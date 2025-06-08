# Manual Testing Guide for Turbo Auto-Save and Progress Updates

## How to Test the Turbo Functionality

Since we can test Turbo Stream responses without Selenium, here are the key areas to verify:

### 1. **Test Auto-Save with Browser Developer Tools**

1. Start the Rails server: `rails s`
2. Log in and create/edit an inspection
3. Open Browser Developer Tools (F12) → Network tab
4. Start typing in any assessment form field
5. Watch for PATCH requests to `/inspections/:id` after 2 seconds of typing
6. Check the request headers include: `Accept: text/vnd.turbo-stream.html`
7. Check the response is `text/vnd.turbo-stream.html` content type

### 2. **Test Progress Percentage Updates**

1. Edit an inspection with incomplete assessments
2. Note the progress percentage in the overview section
3. Complete a section (fill all required fields)
4. Save the form manually or wait for auto-save
5. **Expected**: Progress percentage should update immediately without page reload

### 3. **Test Finalization Issues Display**

1. Mark an inspection as "completed" status but leave some assessments incomplete
2. View the inspection (show page)
3. **Expected**: See "Finalization Issues" section with specific missing items
4. Go back to edit and complete more assessments
5. **Expected**: Issues list should update as sections are completed

### 4. **Test Auto-Save Visual Indicator**

1. Edit any assessment form
2. Start typing in a field
3. **Expected**: See "Saving..." indicator in top-right corner
4. After save completes: See "Saved!" confirmation
5. Indicator should fade out after 3 seconds

## Key Technical Implementation Points

### Controller Response Format
```ruby
format.turbo_stream do
  render turbo_stream: [
    turbo_stream.replace("inspection_progress_#{@inspection.id}") do
      content_tag :span, "#{helpers.assessment_completion_percentage(@inspection)}%", class: "value"
    end,
    turbo_stream.replace("finalization_issues_#{@inspection.id}") do
      # Render finalization issues partial
    end
  ]
end
```

### JavaScript Auto-Save
```javascript
// Sends requests with proper headers
headers: {
  'Accept': 'text/vnd.turbo-stream.html',
  'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
}
```

### Turbo Frame Targets
```erb
<%= turbo_frame_tag "inspection_progress_#{@inspection.id}" do %>
  <span class="value"><%= "#{assessment_completion_percentage(@inspection)}%" %></span>
<% end %>
```

## What Should Work Without Page Reloads

✅ Progress percentage updates as assessments are completed  
✅ Finalization issues appear/disappear based on completion status  
✅ Auto-save every 2 seconds with visual feedback  
✅ All form data persists immediately  
✅ Multiple assessment tabs can be edited seamlessly  

## Fallback Behavior

If Turbo fails for any reason:
- Forms still work normally (they'll do full page submissions)
- Data still saves correctly
- Users can manually refresh to see updates
- No functionality is lost, just the enhanced UX

## Testing the Implementation

The key files that implement this functionality:

- **Controller**: `app/controllers/inspections_controller.rb` (turbo_stream format)
- **JavaScript**: `app/javascript/application.js` (auto-save logic)
- **Views**: Assessment form partials with `local: false, turbo_stream: true`
- **CSS**: `app/assets/stylesheets/application.css` (auto-save indicators)

The Turbo implementation enhances the user experience without breaking existing functionality.