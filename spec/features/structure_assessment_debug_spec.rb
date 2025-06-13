require "rails_helper"

RSpec.feature "Structure Assessment Debug", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  
  before { sign_in(user) }
  
  it "shows what's on the structure form" do
    visit edit_inspection_path(inspection, tab: "structure")
    
    # Find all radio buttons on the page
    all('input[type="radio"]').each do |radio|
      puts "Radio: id=#{radio[:id]}, name=#{radio[:name]}, value=#{radio[:value]}"
    end
    
    # Try to find seam_integrity radio buttons specifically
    puts "\nLooking for seam_integrity radio buttons:"
    all('input[name*="seam_integrity"]').each do |input|
      puts "Found: id=#{input[:id]}, name=#{input[:name]}, value=#{input[:value]}, type=#{input[:type]}"
    end
  end
end