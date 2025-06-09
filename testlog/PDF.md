gfx.DrawString("RPII Inspector Issued Report", h1font, XBrushes.Red, 15, 25);
gfx.DrawString("Issued by: " + truncateText(InspectionCompName.Text, 60), h2font, XBrushes.Black, 15, 40);
gfx.DrawString("Issued " + datePicker.Value.ToShortDateString(), h1font, XBrushes.Red, 15, 55);
gfx.DrawString("RPII Reg Number: " + rpiiReg.Text, h1font, XBrushes.Red, 15, 70);
gfx.DrawString("Place of Inspection: " + truncateText(inspectionLocation.Text, 60), regularFontBold, XBrushes.Red, 15, 85);
gfx.DrawString("Unique Report Number: " + uniquereportNum.Text, h2font, XBrushes.Red, 15, 100);
gfx.DrawString("Unit Details", h2font, XBrushes.Black, 15, 130);
gfx.DrawString("Description: " + truncateText(unitDescriptionText.Text, 66), regularFont, XBrushes.Black, 15, 140);
gfx.DrawString("Manufacturer: " + truncateText(ManufacturerText.Text, 60), regularFont, XBrushes.Black, 15, 148);
gfx.DrawString("Size (m): Width: " + unitWidthNum.Value.ToString() + " Length: " + unitLengthNum.Value.ToString() + " Height: " + unitHeightNum.Value.ToString(), regularFont, XBrushes.Black, 15, 156);
gfx.DrawString("Serial: " + truncateText(serialText.Text, 60), regularFont, XBrushes.Black, 15, 164);
gfx.DrawString("Unit Type: " + truncateText(unitTypeText.Text, 60), regularFont, XBrushes.Black, 15, 172);
gfx.DrawString("Unit Owner: " + truncateText(unitOwnerText.Text, 60), regularFont, XBrushes.Black, 15, 180);
gfx.DrawString("User Height/Count", h2font, XBrushes.Black, 15, 195);
gfx.DrawString("Containing Wall Height: " + containingWallHeightValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 205);
gfx.DrawString("Comment: " + truncateText(containingWallHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 213);
gfx.DrawString("Tallest Platform Height: " + platformHeightValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 221);
gfx.DrawString("Comment: " + truncateText(platformHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 229);
gfx.DrawString("First Metre of Slide Height: " + slidebarrierHeightValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 237);
gfx.DrawString("Comment: " + truncateText(slideBarrierHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 245);
gfx.DrawString("Remaining Slide Wall Height: " + remainingSlideWallHeightValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 253);
gfx.DrawString("Comment: " + truncateText(remainingSlideWallHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 261);
gfx.DrawString("Permanant Roof Fitted: " + permanentRoofChecked.Checked.ToString(), regularFont, XBrushes.Black, 15, 269);
gfx.DrawString("Comment: " + truncateText(permRoofComment.Text, 60), regularFont, XBrushes.Black, 15, 277);
gfx.DrawString("Tallest User Height: " + userHeight.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 285);
gfx.DrawString("Comment: " + truncateText(userHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 293);
gfx.DrawString("Internal Play Area Length: " + playAreaLengthValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 301);
gfx.DrawString("Comment: " + truncateText(playAreaLengthComment.Text, 60), regularFont, XBrushes.Black, 15, 309);
gfx.DrawString("Internal Play Area Width: " + playAreaWidthValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 317);
gfx.DrawString("Comment: " + truncateText(playAreaWidthComment.Text, 60), regularFont, XBrushes.Black, 15, 325);
gfx.DrawString("Negative Adjustment: " + negAdjustmentValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 333);
gfx.DrawString("Comment: " + truncateText(negAdjustmentComment.Text, 60), regularFont, XBrushes.Black, 15, 341);
gfx.DrawString("Users @ 1.0m: " + usersat1000mm.Value.ToString() + " Users @ 1.2m: " + usersat1200mm.Value.ToString(), regularFont, XBrushes.Black, 15, 349);
gfx.DrawString("Users @ 1.5m: " + usersat1200mm.Value.ToString() + " Users @ 1.8m: " + usersat1800mm.Value.ToString(), regularFont, XBrushes.Black, 15, 357);
gfx.DrawString("Slide", h2font, XBrushes.Black, 15, 372);
gfx.DrawString("Slide Platform Height: " + slidePlatformHeightValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 382);
gfx.DrawString("Comment: " + truncateText(slidePlatformHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 390);
gfx.DrawString("Containing Wall Height: " + slideWallHeightValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 398);
gfx.DrawString("Comment: " + truncateText(slideWallHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 406);
gfx.DrawString("First Metre Slide Wall Height: " + slidefirstmetreHeightValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 414);
gfx.DrawString("Comment: " + truncateText(slideFirstMetreHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 422);
gfx.DrawString("Remaining Slide Wall Height: " + beyondfirstmetreHeightValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 430);
gfx.DrawString("Comment: " + truncateText(beyondfirstmetreHeightComment.Text, 60), regularFont, XBrushes.Black, 15, 438);
gfx.DrawString("Perm Slide Roof Fitted: " + slidePermRoofedCheck.Checked.ToString(), regularFont, XBrushes.Black, 15, 446);
gfx.DrawString("Comment: " + truncateText(slidePermRoofedComment.Text, 60), regularFont, XBrushes.Black, 15, 454);
gfx.DrawString("Steps/Clamber Netting Pass/Fail: " + clamberNettingPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 462);
gfx.DrawString("Comment: " + truncateText(clamberNettingComment.Text, 60), regularFont, XBrushes.Black, 15, 470);
gfx.DrawString("Slide Run Out: " + runoutValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 478);
gfx.DrawString("Slide Run Out Pass/Fail: " + runOutPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 486);
gfx.DrawString("Comment: " + truncateText(runoutComment.Text, 60), regularFont, XBrushes.Black, 15, 494);
gfx.DrawString("Slip Sheet Integrity Pass/Fail: " + slipsheetPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 502);
gfx.DrawString("Comment: " + truncateText(slipsheetComment.Text, 60), regularFont, XBrushes.Black, 15, 510);
gfx.DrawString("Structure", h2font, XBrushes.Black, 15, 525);
gfx.DrawString("Seam Integrity Pass/Fail: " + seamIntegrityPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 535);
gfx.DrawString("Comment: " + truncateText(seamIntegrityComment.Text, 60), regularFont, XBrushes.Black, 15, 543);
gfx.DrawString("Lock Stitching Pass/Fail: " + lockstitchPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 551);
gfx.DrawString("Comment: " + truncateText(lockStitchComment.Text, 60), regularFont, XBrushes.Black, 15, 559);
gfx.DrawString("Stitch Length: " + stitchLengthValue.Value.ToString() + "mm", regularFont, XBrushes.Black, 15, 567);
gfx.DrawString("Stitch Length Pass/Fail: " + stitchLengthPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 575);
gfx.DrawString("Comment: " + truncateText(stitchLengthComment.Text, 60), regularFont, XBrushes.Black, 15, 583);
gfx.DrawString("Air Loss Pass/Fail: " + airLossPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 591);
gfx.DrawString("Comment: " + truncateText(airLossComment.Text, 60), regularFont, XBrushes.Black, 15, 599);
gfx.DrawString("Walls and Turrets Vertical Pass/Fail: " + wallStraightPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 607);
gfx.DrawString("Comment: " + truncateText(wallStraightComment.Text, 60), regularFont, XBrushes.Black, 15, 615);
gfx.DrawString("Sharp/Square/Pointed Edges Pass/Fail: " + sharpEdgesPassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 623);
gfx.DrawString("Comment: " + truncateText(sharpEdgesComment.Text, 60), regularFont, XBrushes.Black, 15, 631);
gfx.DrawString("Blower Tube Distance: " + tubeDistanceValue.Value.ToString() + "m", regularFont, XBrushes.Black, 15, 639);
gfx.DrawString("Blower Tube Pass/Fail: " + tubeDistancePassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 647);
gfx.DrawString("Comment: " + truncateText(tubeDistanceComment.Text, 60), regularFont, XBrushes.Black, 15, 655);
gfx.DrawString("Unit Stable Pass/Fail: " + stablePassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 663);
gfx.DrawString("Comment: " + truncateText(stableComment.Text, 60), regularFont, XBrushes.Black, 15, 671);
gfx.DrawString("Evacuation Time: " + evacTime.Value.ToString() + "s", regularFont, XBrushes.Black, 15, 679);
gfx.DrawString("Evacuation Time Pass/Fail: " + evacTimePassFail.Checked.ToString(), regularFont, XBrushes.Black, 15, 687);
gfx.DrawString("Comment: " + truncateText(evacTimeComment.Text, 60), regularFont, XBrushes.Black, 15, 695);
gfx.DrawString("Structure Cont.", h2font, XBrushes.Black, 312.5, 130);
gfx.DrawString("Step/Ramp Size: " + stepSizeValue.Value.ToString() + "m", regularFont, XBrushes.Black, 312.5, 140);
gfx.DrawString("Step/Ramp Size Pass/Fail: " + stepSizePassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 148);
gfx.DrawString("Comment: " + truncateText(stepSizeComment.Text, 60), regularFont, XBrushes.Black, 312.5, 156);
gfx.DrawString("Critical Fall Off Height: " + falloffHeight.Value.ToString() + "m", regularFont, XBrushes.Black, 312.5, 164);
gfx.DrawString("Critical Fall Off Height Pass/Fail: " + falloffHeightPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 172);
gfx.DrawString("Comment: " + truncateText(falloffHeightComment.Text, 60), regularFont, XBrushes.Black, 312.5, 180);
gfx.DrawString("Critical Fall Off Height: " + falloffHeight.Value.ToString() + "m", regularFont, XBrushes.Black, 312.5, 188);
gfx.DrawString("Critical Fall Off Height Pass/Fail: " + falloffHeightPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 196);
gfx.DrawString("Comment: " + truncateText(falloffHeightComment.Text, 60), regularFont, XBrushes.Black, 312.5, 204);
gfx.DrawString("Unit Pressure: " + pressureValue.Value.ToString() + "Kpa", regularFont, XBrushes.Black, 312.5, 212);
gfx.DrawString("Unit Pressure Pass/Fail: " + pressurePassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 220);
gfx.DrawString("Comment: " + truncateText(pressureComment.Text, 60), regularFont, XBrushes.Black, 312.5, 228);
gfx.DrawString("Trough Depth: " + troughDepthValue.Value.ToString() + "mm", regularFont, XBrushes.Black, 312.5, 236);
gfx.DrawString("Trough Adjacent Panel Width: " + troughWidthValue.Value.ToString() + "mm", regularFont, XBrushes.Black, 312.5, 244);
gfx.DrawString("Trough Pass/Fail: " + troughPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 252);
gfx.DrawString("Comment: " + truncateText(troughComment.Text, 60), regularFont, XBrushes.Black, 312.5, 260);
gfx.DrawString("Entrapment Pass/Fail: " + entrapPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 268);
gfx.DrawString("Comment: " + truncateText(entrapComment.Text, 60), regularFont, XBrushes.Black, 312.5, 276);
gfx.DrawString("Markings/ID Pass/Fail: " + markingsPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 284);
gfx.DrawString("Comment: " + truncateText(markingsComment.Text, 60), regularFont, XBrushes.Black, 312.5, 292);
gfx.DrawString("Grounding Pass/Fail: " + groundingPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 300);
gfx.DrawString("Comment: " + truncateText(groundingComment.Text, 60), regularFont, XBrushes.Black, 312.5, 308);
gfx.DrawString("Anchorage", h2font, XBrushes.Black, 312.5, 323);
gfx.DrawString("Number of Anchors: " + (numHighAnchors.Value + numLowAnchors.Value).ToString(), regularFont, XBrushes.Black, 312.5, 333);
gfx.DrawString("Number of Anchors Pass/Fail: " + numAnchorsPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 341);
gfx.DrawString("Comment: " + truncateText(numAnchorsComment.Text, 60), regularFont, XBrushes.Black, 312.5, 349);
gfx.DrawString("Anchor Accessories Pass/Fail: " + anchorAccessoriesPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 357);
gfx.DrawString("Comment: " + truncateText(AnchorAccessoriesComment.Text, 60), regularFont, XBrushes.Black, 312.5, 365);
gfx.DrawString("Anchors Between 30-45� Pass/Fail: " + anchorDegreePassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 373);
gfx.DrawString("Comment: " + truncateText(anchorDegreesComment.Text, 60), regularFont, XBrushes.Black, 312.5, 381);
gfx.DrawString("Anchors Perm Closed Pass/Fail: " + anchorTypePassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 389);
gfx.DrawString("Comment: " + truncateText(anchorTypeComment.Text, 60), regularFont, XBrushes.Black, 312.5, 397);
gfx.DrawString("Pull Strength Pass/Fail: " + pullStrengthPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 405);
gfx.DrawString("Comment: " + truncateText(pullStrengthComment.Text, 60), regularFont, XBrushes.Black, 312.5, 413);
gfx.DrawString("Totally Enclosed", h2font, XBrushes.Black, 312.5, 428);
gfx.DrawString("Number of Exits: " + exitNumberValue.Value.ToString(), regularFont, XBrushes.Black, 312.5, 438);
gfx.DrawString("Number of Exits Pass/Fail: " + exitNumberPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 446);
gfx.DrawString("Comment: " + truncateText(exitNumberComment.Text, 60), regularFont, XBrushes.Black, 312.5, 454);
gfx.DrawString("Number of Exits Pass/Fail: " + exitsignVisiblePassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 462);
gfx.DrawString("Comment: " + truncateText(exitSignVisibleComment.Text, 60), regularFont, XBrushes.Black, 312.5, 470);
gfx.DrawString("Materials", h2font, XBrushes.Black, 312.5, 485);
gfx.DrawString("Ropes: " + ropesizeValue.Value.ToString() + "mm", regularFont, XBrushes.Black, 312.5, 495);
gfx.DrawString("Ropes Pass/Fail: " + ropeSizePassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 503);
gfx.DrawString("Comment: " + truncateText(ropeSizeComment.Text, 60), regularFont, XBrushes.Black, 312.5, 511);
gfx.DrawString("Clamber Netting Pass/Fail: " + clamberPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 519);
gfx.DrawString("Comment: " + truncateText(clamberComment.Text, 60), regularFont, XBrushes.Black, 312.5, 527);
gfx.DrawString("Retention Netting Pass/Fail: " + retentionNettingPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 535);
gfx.DrawString("Comment: " + truncateText(retentionNettingComment.Text, 60), regularFont, XBrushes.Black, 312.5, 543);
gfx.DrawString("Zips Pass/Fail: " + zipsPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 551);
gfx.DrawString("Comment: " + truncateText(zipsComment.Text, 60), regularFont, XBrushes.Black, 312.5, 559);
gfx.DrawString("Windows Pass/Fail: " + windowsPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 567);
gfx.DrawString("Comment: " + truncateText(windowsComment.Text, 60), regularFont, XBrushes.Black, 312.5, 575);
gfx.DrawString("Artwork Pass/Fail: " + artworkPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 583);
gfx.DrawString("Comment: " + truncateText(artworkComment.Text, 60), regularFont, XBrushes.Black, 312.5, 591);
gfx.DrawString("Thread Pass/Fail: " + threadPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 599);
gfx.DrawString("Comment: " + truncateText(threadComment.Text, 60), regularFont, XBrushes.Black, 312.5, 607);
gfx.DrawString("Fabric Strength Pass/Fail: " + fabricPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 615);
gfx.DrawString("Comment: " + truncateText(fabricComment.Text, 60), regularFont, XBrushes.Black, 312.5, 623);
gfx.DrawString("Fire Retardent Pass/Fail: " + fireRetardentPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 631);
gfx.DrawString("Comment: " + truncateText(fireRetardentComment.Text, 60), regularFont, XBrushes.Black, 312.5, 639);
gfx.DrawString("Fan/Blower", h2font, XBrushes.Black, 312.5, 654);
gfx.DrawString("Comment: " + truncateText(blowerSizeComment.Text, 60), regularFont, XBrushes.Black, 312.5, 664);
gfx.DrawString("Return Flap Pass/Fail: " + blowerFlapPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 672);
gfx.DrawString("Comment: " + truncateText(blowerFlapComment.Text, 60), regularFont, XBrushes.Black, 312.5, 680);
gfx.DrawString("Finger Probe Test Pass/Fail: " + blowerFingerPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 688);
gfx.DrawString("Comment: " + truncateText(blowerFingerComment.Text, 60), regularFont, XBrushes.Black, 312.5, 696);
gfx.DrawString("PAT Test Pass/Fail: " + patPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 704);
gfx.DrawString("Comment: " + truncateText(patComment.Text, 60), regularFont, XBrushes.Black, 312.5, 712);
gfx.DrawString("Visual Inspection Pass/Fail: " + blowerVisualPassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 720);
gfx.DrawString("Comment: " + truncateText(blowerVisualComment.Text, 60), regularFont, XBrushes.Black, 312.5, 728);
gfx.DrawString("Blower Serial: " + truncateText(blowerSerial.Text, 60), regularFont, XBrushes.Black, 312.5, 736);
gfx.DrawString("Risk Assessment", h2font, XBrushes.Black, 15, 748);
gfx.DrawString("Result: ", h1font, XBrushes.Black, 15, 836);
gfx.DrawString("Failed Inspection", h1font, XBrushes.Red, 74, 836);
gfx.DrawString("Passed Inspection", h1font, XBrushes.Green, 74, 836);

# MISSING FROM RAILS PDF GENERATOR

## Structure Assessment - Missing Fields:
- Step/Ramp Size (value + pass/fail)
- Critical Fall Off Height (value + pass/fail) 
- Unit Pressure (value in Kpa + pass/fail)
- Trough Depth (value in mm)
- Trough Adjacent Panel Width (value in mm) 
- Trough Pass/Fail assessment
- Entrapment Pass/Fail assessment
- Markings/ID Pass/Fail assessment
- Grounding Pass/Fail assessment

## Materials Assessment - Missing Fields:
- Clamber Netting Pass/Fail
- Retention Netting Pass/Fail
- Zips Pass/Fail
- Windows Pass/Fail
- Artwork Pass/Fail

## Fan/Blower Assessment - Missing Fields:
- Blower Serial Number

## Totally Enclosed Assessment - Missing Fields:
- Exit Sign Visible Pass/Fail (separate from exit count)

## Missing Sections:
- Risk Assessment section

## Notes:
- Most pass/fail fields that are "missing" are actually combined with their values in our Rails app
- The above list represents actual missing functionality, not just formatting differences
- Comments are handled differently (integrated) but provide equivalent functionality
