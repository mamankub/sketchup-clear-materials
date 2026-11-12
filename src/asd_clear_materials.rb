# encoding: UTF-8
# ASD Clear Materials - loader
require 'sketchup.rb'
require 'extensions.rb'

module ASD
  module ClearMaterials
    PLUGIN_ID   = 'asd_clear_materials'.freeze
    PLUGIN_NAME = 'ASD Clear Materials'.freeze
    VERSION     = '1.0.0'.freeze

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new(PLUGIN_NAME, File.join(PLUGIN_ID, 'main'))
      ex.description = 'ล้างสี/วัสดุ ให้กลับเป็น Default (ไร้สี) ทั้งในส่วนที่เลือกหรือทั้งโมเดล ' \
                       'รวมถึงกลุ่มและคอมโพเนนต์ที่ซ้อนอยู่ด้านใน'
      ex.version     = VERSION
      ex.creator     = 'ASD'
      ex.copyright   = '2026 ASD'
      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end
  end
end
