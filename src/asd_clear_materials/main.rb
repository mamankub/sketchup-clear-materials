# encoding: UTF-8
# ASD Clear Materials - main logic
#
# Resets materials to Default (nil) on faces (front + back), edges,
# groups and component instances, recursing into nested definitions.
# Every command is a single undo step (Ctrl+Z reverts it in one go).

require 'sketchup.rb'
require 'set'

module ASD
  module ClearMaterials

    # --- core ---------------------------------------------------------------

    def self.new_stats
      { :faces => 0, :edges => 0, :containers => 0, :definitions => 0 }
    end

    # Clear one entity's own material (and back material for faces).
    def self.clear_entity(e, stats)
      if e.is_a?(Sketchup::Face)
        changed = false
        if e.material
          e.material = nil
          changed = true
        end
        if e.back_material
          e.back_material = nil
          changed = true
        end
        stats[:faces] += 1 if changed
      elsif e.is_a?(Sketchup::Edge)
        if e.material
          e.material = nil
          stats[:edges] += 1
        end
      elsif e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
        if e.material
          e.material = nil
          stats[:containers] += 1
        end
      end
    end

    def self.definition_of(e)
      if e.is_a?(Sketchup::ComponentInstance)
        e.definition
      elsif e.is_a?(Sketchup::Group)
        e.respond_to?(:definition) ? e.definition : e.entities.parent
      end
    end

    # Clear a collection of entities; when recursive, also clear the
    # contents of every group/component found (each definition once).
    def self.clear_list(list, recursive, visited, stats)
      list.each do |e|
        next unless e.valid?
        clear_entity(e, stats)
        next unless recursive
        defn = definition_of(e)
        next if defn.nil? || visited.include?(defn)
        visited.add(defn)
        stats[:definitions] += 1
        clear_list(defn.entities.to_a, true, visited, stats)
      end
    end

    def self.run(op_name)
      model = Sketchup.active_model
      stats = new_stats
      model.start_operation(op_name, true)
      begin
        yield(model, stats)
        model.commit_operation
      rescue Exception => err
        model.abort_operation
        UI.messagebox("เกิดข้อผิดพลาด: #{err.message}")
        puts err.backtrace.join("\n") if err.backtrace
        return nil
      end
      stats
    end

    def self.report(stats, extra = nil)
      return unless stats
      total = stats[:faces] + stats[:edges] + stats[:containers]
      msg = "ล้างสีเรียบร้อย\n\n" \
            "หน้า (Face): #{stats[:faces]}\n" \
            "เส้น (Edge): #{stats[:edges]}\n" \
            "กลุ่ม/คอมโพเนนต์: #{stats[:containers]}\n" \
            "เข้าไปล้างด้านใน: #{stats[:definitions]} definition\n" \
            "รวมที่เปลี่ยน: #{total}"
      msg << "\n\n#{extra}" if extra
      msg << "\n\n(กด Ctrl+Z เพื่อย้อนกลับได้ในครั้งเดียว)"
      UI.messagebox(msg)
    end

    # --- commands -----------------------------------------------------------

    # Selection, including everything nested inside selected groups/components.
    def self.clear_selection(recursive = true)
      model = Sketchup.active_model
      sel = model.selection.to_a
      if sel.empty?
        UI.messagebox('กรุณาเลือกชิ้นงานก่อน (หรือใช้คำสั่ง "ล้างสีทั้งโมเดล")')
        return
      end
      stats = run('ล้างสี (ส่วนที่เลือก)') do |_m, s|
        clear_list(sel, recursive, Set.new, s)
      end
      report(stats)
    end

    # Entire model: top level + every definition (incl. unplaced ones).
    def self.clear_model
      res = UI.messagebox('ล้างสี/วัสดุ ทุกชิ้นงานในโมเดลให้เป็น Default ใช่ไหม?', MB_YESNO)
      return unless res == IDYES
      purge = UI.messagebox('ลบวัสดุที่ไม่ได้ใช้แล้วออกจาก In Model ด้วยไหม? (Purge)', MB_YESNO) == IDYES
      purged = 0
      stats = run('ล้างสี (ทั้งโมเดล)') do |m, s|
        visited = Set.new
        clear_list(m.entities.to_a, true, visited, s)
        m.definitions.each do |d|
          next if d.image? || visited.include?(d)
          visited.add(d)
          s[:definitions] += 1
          clear_list(d.entities.to_a, true, visited, s)
        end
        if purge
          before = m.materials.length
          m.materials.purge_unused
          purged = before - m.materials.length
        end
      end
      report(stats, purge ? "ลบวัสดุที่ไม่ได้ใช้: #{purged} รายการ" : nil)
    end

    def self.purge_materials
      model = Sketchup.active_model
      before = model.materials.length
      model.start_operation('ลบวัสดุที่ไม่ได้ใช้', true)
      model.materials.purge_unused
      model.commit_operation
      UI.messagebox("ลบวัสดุที่ไม่ได้ใช้: #{before - model.materials.length} รายการ")
    end

    # --- UI -----------------------------------------------------------------

    unless file_loaded?(__FILE__)
      menu = UI.menu('Extensions').add_submenu('ASD ล้างสี (Clear Materials)')
      menu.add_item('ล้างสีส่วนที่เลือก (รวมด้านในกลุ่ม/คอมโพเนนต์)') { clear_selection(true) }
      menu.add_item('ล้างสีส่วนที่เลือก (เฉพาะชั้นนอก)') { clear_selection(false) }
      menu.add_separator
      menu.add_item('ล้างสีทั้งโมเดล') { clear_model }
      menu.add_separator
      menu.add_item('ลบวัสดุที่ไม่ได้ใช้ (Purge Materials)') { purge_materials }

      UI.add_context_menu_handler do |context_menu|
        unless Sketchup.active_model.selection.empty?
          context_menu.add_separator
          context_menu.add_item('ASD: ล้างสีเป็น Default') { clear_selection(true) }
        end
      end

      cmd = UI::Command.new('ASD ล้างสี') { clear_selection(true) }
      cmd.tooltip = 'ล้างสีส่วนที่เลือกเป็น Default'
      cmd.status_bar_text = 'ล้างสี/วัสดุ ของชิ้นงานที่เลือก รวมทั้งด้านในกลุ่มและคอมโพเนนต์'
      icon = File.join(File.dirname(__FILE__), 'icons', 'clear')
      cmd.small_icon = "#{icon}_24.png"
      cmd.large_icon = "#{icon}_32.png"
      cmd2 = UI::Command.new('ASD ล้างสีทั้งโมเดล') { clear_model }
      cmd2.tooltip = 'ล้างสีทั้งโมเดลเป็น Default'
      cmd2.status_bar_text = 'ล้างสี/วัสดุ ทุกชิ้นงานในโมเดล'
      icon2 = File.join(File.dirname(__FILE__), 'icons', 'clear_all')
      cmd2.small_icon = "#{icon2}_24.png"
      cmd2.large_icon = "#{icon2}_32.png"
      tb = UI::Toolbar.new('ASD Clear Materials')
      tb.add_item(cmd)
      tb.add_item(cmd2)
      if tb.get_last_state == TB_NEVER_SHOWN
        tb.show
      else
        tb.restore
      end

      file_loaded(__FILE__)
    end

  end
end
