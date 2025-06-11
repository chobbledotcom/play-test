#!/usr/bin/env nix-shell
#! nix-shell -i bash -p imagemagick exiftool

# Create test images with different EXIF orientations for testing image processing

FIXTURES_DIR="spec/fixtures/files"
mkdir -p "$FIXTURES_DIR"

echo "Creating test images with EXIF orientations..."

# Create a base landscape image (100x60) - blue rectangle
magick -size 100x60 xc:blue "$FIXTURES_DIR/base_landscape.jpg"

# Create a base portrait image (60x100) - red rectangle
magick -size 60x100 xc:red "$FIXTURES_DIR/base_portrait.jpg"

# Create images with different EXIF orientations
# Orientation 1: Normal (no rotation needed)
cp "$FIXTURES_DIR/base_landscape.jpg" "$FIXTURES_DIR/orientation_1_normal.jpg"
exiftool -Orientation#=1 -overwrite_original "$FIXTURES_DIR/orientation_1_normal.jpg"

# Orientation 2: Horizontal flip
cp "$FIXTURES_DIR/base_landscape.jpg" "$FIXTURES_DIR/orientation_2_flip_horizontal.jpg"
exiftool -Orientation#=2 -overwrite_original "$FIXTURES_DIR/orientation_2_flip_horizontal.jpg"

# Orientation 3: 180° rotation
cp "$FIXTURES_DIR/base_landscape.jpg" "$FIXTURES_DIR/orientation_3_rotate_180.jpg"
exiftool -Orientation#=3 -overwrite_original "$FIXTURES_DIR/orientation_3_rotate_180.jpg"

# Orientation 4: Vertical flip
cp "$FIXTURES_DIR/base_landscape.jpg" "$FIXTURES_DIR/orientation_4_flip_vertical.jpg"
exiftool -Orientation#=4 -overwrite_original "$FIXTURES_DIR/orientation_4_flip_vertical.jpg"

# Orientation 5: Transpose (flip + 90° clockwise)
cp "$FIXTURES_DIR/base_landscape.jpg" "$FIXTURES_DIR/orientation_5_transpose.jpg"
exiftool -Orientation#=5 -overwrite_original "$FIXTURES_DIR/orientation_5_transpose.jpg"

# Orientation 6: 90° clockwise rotation
cp "$FIXTURES_DIR/base_landscape.jpg" "$FIXTURES_DIR/orientation_6_rotate_90_cw.jpg"
exiftool -Orientation#=6 -overwrite_original "$FIXTURES_DIR/orientation_6_rotate_90_cw.jpg"

# Orientation 7: Transverse (flip + 90° counter-clockwise)
cp "$FIXTURES_DIR/base_landscape.jpg" "$FIXTURES_DIR/orientation_7_transverse.jpg"
exiftool -Orientation#=7 -overwrite_original "$FIXTURES_DIR/orientation_7_transverse.jpg"

# Orientation 8: 90° counter-clockwise rotation
cp "$FIXTURES_DIR/base_landscape.jpg" "$FIXTURES_DIR/orientation_8_rotate_90_ccw.jpg"
exiftool -Orientation#=8 -overwrite_original "$FIXTURES_DIR/orientation_8_rotate_90_ccw.jpg"

# Create a larger test image for dimension testing
magick -size 1600x1200 xc:green "$FIXTURES_DIR/large_landscape.jpg"
exiftool -Orientation#=6 -overwrite_original "$FIXTURES_DIR/large_landscape.jpg"

# Create an image without EXIF data
magick -size 80x80 xc:yellow "$FIXTURES_DIR/no_exif.jpg"
exiftool -all= -overwrite_original "$FIXTURES_DIR/no_exif.jpg"

echo "Test images created in $FIXTURES_DIR:"
echo "- orientation_1_normal.jpg (no rotation needed)"
echo "- orientation_2_flip_horizontal.jpg (horizontal flip)"
echo "- orientation_3_rotate_180.jpg (180° rotation)"
echo "- orientation_4_flip_vertical.jpg (vertical flip)"
echo "- orientation_5_transpose.jpg (transpose)"
echo "- orientation_6_rotate_90_cw.jpg (90° clockwise)"
echo "- orientation_7_transverse.jpg (transverse)"
echo "- orientation_8_rotate_90_ccw.jpg (90° counter-clockwise)"
echo "- large_landscape.jpg (1600x1200 with orientation 6)"
echo "- no_exif.jpg (no EXIF data)"

echo ""
echo "Verifying EXIF orientations:"
for file in "$FIXTURES_DIR"/orientation_*.jpg "$FIXTURES_DIR"/large_landscape.jpg; do
    if [ -f "$file" ]; then
        orientation=$(exiftool -Orientation -n "$file" | cut -d: -f2 | tr -d ' ')
        echo "$(basename "$file"): Orientation $orientation"
    fi
done

echo ""
echo "No EXIF data files:"
exiftool -Orientation "$FIXTURES_DIR/no_exif.jpg" || echo "no_exif.jpg: No orientation data (as expected)"

echo ""
echo "Done! Run the script with: chmod +x create_test_images.sh && ./create_test_images.sh"