require 'sketchup.rb'

# --- Закрыть старый диалог, если был ---
if $kcode_dialog
    begin
        $kcode_dialog.close
    rescue StandardError
    end
    $kcode_dialog = nil
end

# --- Загрузка модулей (порядок важен) ---
load File.join(__dir__, 'constants.rb')
load File.join(__dir__, 'suppress.rb')
load File.join(__dir__, 'model_context.rb')
load File.join(__dir__, 'axis.rb')
load File.join(__dir__, 'side.rb')
load File.join(__dir__, 'context.rb')
load File.join(__dir__, 'observers.rb')
load File.join(__dir__, 'editor.rb')

# --- Подписка наблюдателей на активную модель ---
if $kcode_placement_observer
    begin
        Sketchup.active_model.remove_observer($kcode_placement_observer)
    rescue StandardError
    end
end
$kcode_placement_observer = MyName::KCode::PlacementObserver.new
Sketchup.active_model.add_observer($kcode_placement_observer)

if $kcode_instance_observer
    begin
        Sketchup.active_model.entities.each do |e|
            e.remove_observer($kcode_instance_observer) if e.respond_to?(:remove_observer)
        end
    rescue StandardError
    end
end
$kcode_instance_observer = MyName::KCode::InstanceObserver.new
Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).each do |inst|
    next unless inst.valid?
    inst.add_observer($kcode_instance_observer)
end

if $kcode_tx_observer
    begin
        Sketchup.active_model.remove_observer($kcode_tx_observer)
    rescue StandardError
    end
end
$kcode_tx_observer = MyName::KCode::TransactionObserver.new
Sketchup.active_model.add_observer($kcode_tx_observer)

if $kcode_entities_added_observer
    begin
        Sketchup.active_model.entities.remove_observer($kcode_entities_added_observer)
    rescue StandardError
    end
end
$kcode_entities_added_observer = MyName::KCode::EntitiesAddedObserver.new
Sketchup.active_model.entities.add_observer($kcode_entities_added_observer)

# --- Меню ---
unless $kcode_menu_registered
    extensions_menu = UI.menu('Extensions')
    extensions_menu.add_item('KCode: редактор кода компонента') do
        MyName::KCode.show_editor
    end
    $kcode_menu_registered = true
end

puts '[KCode] Загружено: ' + Dir.glob(File.join(__dir__, '*.rb')).map { |f| File.basename(f) }.sort.join(', ')