# encoding: UTF-8
# Minimal SketchUp API mock to exercise main.rb logic outside SketchUp.
$messages = []
$loaded = {}
def file_loaded?(f); $loaded[f]; end
def file_loaded(f); $loaded[f] = true; end
MB_YESNO = 4; IDYES = 6; TB_NEVER_SHOWN = -1
$answer = IDYES

module UI
  def self.messagebox(m, t = nil); $messages << m; $answer; end
  class Menu
    attr_reader :items
    def initialize; @items = {}; end
    def add_submenu(_n); self; end
    def add_item(n, &b); @items[n] = b; end
    def add_separator; end
  end
  MENU = Menu.new
  def self.menu(_n); MENU; end
  def self.add_context_menu_handler(&b); end
  class Command
    attr_accessor :tooltip, :status_bar_text, :small_icon, :large_icon
    def initialize(_n, &b); end
  end
  class Toolbar
    def initialize(_n); end
    def add_item(_c); end
    def get_last_state; TB_NEVER_SHOWN; end
    def show; end
    def restore; end
  end
end

module Sketchup
  class Ent
    attr_accessor :material
    def initialize(m = nil); @material = m; end
    def valid?; true; end
  end
  class Face < Ent; attr_accessor :back_material
    def initialize(m, b = nil); super(m); @back_material = b; end
  end
  class Edge < Ent; end
  class Definition
    attr_reader :entities
    def initialize(ents, image = false); @entities = ents; @image = image; end
    def image?; @image; end
  end
  class Group < Ent; attr_reader :definition
    def initialize(m, d); super(m); @definition = d; end
    def entities; @definition.entities; end
  end
  class ComponentInstance < Group; end
  class Materials
    def initialize; @list = %w[a b c d]; end
    def length; @list.length; end
    def purge_unused; @list = %w[a]; end
  end
  class Model
    attr_accessor :entities, :definitions, :selection, :ops
    attr_reader :materials
    def initialize; @materials = Materials.new; @ops = []; end
    def start_operation(n, _d); @ops << [:start, n]; end
    def commit_operation; @ops << [:commit]; end
    def abort_operation; @ops << [:abort]; end
  end
  def self.active_model; $model; end
end
$LOADED_FEATURES << 'sketchup.rb'
require_relative '../src/asd_clear_materials/main'

def check(c, msg); raise "FAIL: #{msg}" unless c; puts "ok - #{msg}"; end

# Build: tile component (shared def, faces painted) used by 2 instances,
# group nesting another component, a loose face.
tile_def = Sketchup::Definition.new([Sketchup::Face.new('blue', 'blue'), Sketchup::Edge.new('black')])
inner_def = Sketchup::Definition.new([Sketchup::Face.new('red')])
inner_inst = Sketchup::ComponentInstance.new('green', inner_def)
grp_def = Sketchup::Definition.new([inner_inst, Sketchup::Face.new('grey')])
grp = Sketchup::Group.new('white', grp_def)
t1 = Sketchup::ComponentInstance.new('blue', tile_def)
t2 = Sketchup::ComponentInstance.new('blue', tile_def)
loose = Sketchup::Face.new('x', 'y')
unplaced = Sketchup::Definition.new([Sketchup::Face.new('z')])

$model = Sketchup::Model.new
$model.entities = [t1, t2, grp, loose]
$model.definitions = [tile_def, inner_def, grp_def, unplaced, Sketchup::Definition.new([], true)]

# 1) Selection, outer only
$model.selection = [grp]
ASD::ClearMaterials.clear_selection(false)
check grp.material.nil?, 'outer-only clears group material'
check grp_def.entities[1].material == 'grey', 'outer-only leaves nested face'

# 2) Selection recursive
$model.selection = [grp, t1]
ASD::ClearMaterials.clear_selection(true)
check inner_inst.material.nil? && inner_def.entities[0].material.nil?, 'recursive clears nested component'
check grp_def.entities[1].material.nil?, 'recursive clears faces in group'
check tile_def.entities[0].back_material.nil? && tile_def.entities[1].material.nil?, 'clears back material + edges'
check t2.material == 'blue', 'unselected instance own material untouched'
check loose.material == 'x', 'unselected loose face untouched'
check $model.ops.last(2) == [[:start, 'ล้างสี (ส่วนที่เลือก)'], [:commit]], 'single undo op committed'

# 3) Empty selection
$model.selection = []
n = $messages.size
ASD::ClearMaterials.clear_selection(true)
check $messages[n].include?('กรุณาเลือก'), 'empty selection warns'

# 4) Whole model with purge
ASD::ClearMaterials.clear_model
check t2.material.nil? && loose.material.nil? && loose.back_material.nil?, 'whole model clears everything top-level'
check unplaced.entities[0].material.nil?, 'whole model clears unplaced definitions'
check $messages.last.include?('3 รายการ'), 'purge count reported'
puts "\nLast report:\n#{$messages.last}"
puts 'ALL PASSED'
