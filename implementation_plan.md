# Dialogue Bubble Implementation Plan

This document outlines the required changes to fix our dialogue bubble system integration. We'll address each issue in a specific order to ensure a systematic approach.

## Issue 1: Bubble Height & Text Positioning

**Goal:** Make the dialogue bubble dynamically size to fit exactly the lines of text being displayed, with proper text positioning.

### Implementation Steps:

1. **Remove minimum bubble height**

   - Find and remove the line that sets `bubble_height = max(2, used_lines)`
   - Replace with `bubble_height = used_lines`

2. **Fix text line counting**

   - Ensure the loop that counts non-empty lines is accurate
   - Only count lines that have actual text to display

   ```lua
   local used_lines = 0
   for i = 1, dislineslength do
       if dtb_dislines[i] != "" then
           used_lines += 1
       end
   end
   ```

3. **Text placement**
   - Keep the text positioning logic simple using the coordinates returned by `_dtb_draw_bubble`
   - Ensure we're printing only non-empty lines
   ```lua
   for i = 1, dislineslength do
       if dtb_dislines[i] != "" then
           print(dtb_dislines[i], text_x, text_y + (i-1) * 6, 7)
       end
   end
   ```

## Issue 2: Line Length Adjustment

**Goal:** Ensure text properly fits within the speech bubble without overflowing.

### Implementation Steps:

1. **Reduce character limit per line**

   - In `dtb_disp` function, find the text wrapping logic
   - Change the check for line length:

   ```lua
   -- Find this line:
   if #curword + #currline > 20 then
   -- Change to:
   if #curword + #currline > 16 then
   ```

2. **Update word wrapping threshold**
   - Find the check for long words
   ```lua
   -- Find this line:
   elseif #curword > 19 then
   -- Change to:
   elseif #curword > 15 then
   ```

## Issue 3: Advance Indicator Positioning

**Goal:** Position the advance indicator logically in relation to the text.

### Implementation Steps:

1. **Update indicator logic**

   - Ensure indicator only appears when player can advance text

   ```lua
   if dtb_curline > 0 and dtb_curline >= #dtb_queu[1] and #dtb_dislines[#dtb_dislines] == #dtb_queu[1][dtb_curline] then
       -- Show indicator
   end
   ```

2. **Position indicator relative to text**

   - Place it after the last displayed line of text

   ```lua
   -- Find indicator drawing code:
   print("\x8e", flipped and text_x - 8 or text_x + 32, text_y + (used_lines-1) * 6, 7)

   -- Change to place after the last line:
   local last_line_idx = 0
   for i = dislineslength, 1, -1 do
       if dtb_dislines[i] != "" then
           last_line_idx = i
           break
       end
   end

   local last_line_text = dtb_dislines[last_line_idx]
   local indicator_x = flipped and (text_x - 6) or (text_x + 4 * #last_line_text + 2)
   local indicator_y = text_y + (last_line_idx-1) * 6
   print("\x8e", indicator_x, indicator_y, 7)
   ```

## Testing:

After each set of changes:

1. Test with single-line dialogue
2. Test with multi-line dialogue
3. Test with dialogue that advances line by line
4. Test text positioning near screen edges (should flip correctly)
5. Verify the advance indicator appears in the correct position

## Additional Notes:

- Keep changes minimal - only modify what's needed to fix these specific issues
- Maintain compatibility with the existing dialogue system
- If any change has unexpected side effects, isolate and address it separately
