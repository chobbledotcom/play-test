using Microsoft.VisualBasic.ApplicationServices;
using PdfSharp.Drawing;
using PdfSharp.Drawing.Layout;
using PdfSharp.Fonts;
using PdfSharp.Pdf;
using PdfSharp.UniversalAccessibility.Drawing;
using RestSharp;
using System;
using System.Data;
using System.Data.Entity;
using System.Data.Entity.Core.Mapping;
using System.Data.SQLite;
using System.Diagnostics;
using System.Diagnostics.PerformanceData;
using System.Drawing;
using System.Net;
using System.Net.Http.Headers;
using System.Security.Policy;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using static RPIIUtility.Form1;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.ListView;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.TaskbarClock;

namespace RPIIUtility
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
            datePicker.Value = DateTime.Now;
        }

        string toolName = "RPII Utility";

        private void uploadPhotoBtn_Click(object sender, EventArgs e)
        {
            choosePhoto();
        }

        /*
        This is a little lazy really. I should allow the user to take multiple photos and also directly from the webcam rather than browsing to existing photos.
        I mean, I could look at OpenCvSharp or something - I have used that previously. Would save the user needing to take a photo and save it, then insert it.
        Maybe for a later version though - I just want this out the door.
        */
        void choosePhoto()
        {
            openPhotoFile.ShowDialog();
            if (openPhotoFile.FileName.Length > 0)
            {
                try
                {
                    unitPic.Image = new Bitmap(openPhotoFile.FileName);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, toolName);
                }
            }
        }

        void adPhoto1()
        {
            adPic1.ShowDialog();
            if (adPic1.FileName.Length > 0)
            {
                try
                {
                    AdditionalPic1.Image = new Bitmap(adPic1.FileName);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, toolName);
                }
            }
        }

        void adPhoto2()
        {
            adPic2.ShowDialog();
            if (adPic2.FileName.Length > 0)
            {
                try
                {
                    AdditionalPic2.Image = new Bitmap(adPic2.FileName);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, toolName);
                }
            }
        }

        void adPhoto3()
        {
            adPic3.ShowDialog();
            if (adPic3.FileName.Length > 0)
            {
                try
                {
                    AdditionalPic3.Image = new Bitmap(adPic3.FileName);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, toolName);
                }
            }
        }

        void adPhoto4()
        {
            adPic4.ShowDialog();
            if (adPic4.FileName.Length > 0)
            {
                try
                {
                    AdditionalPic4.Image = new Bitmap(adPic4.FileName);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, toolName);
                }
            }
        }

        void chooseLogo()
        {
            openLogoFile.ShowDialog();
            if (openLogoFile.FileName.Length > 0)
            {
                try
                {
                    inspectorsLogo.Image = new Bitmap(openLogoFile.FileName);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, toolName);
                }
            }
        }


        //Creates the database (not the table) if it doesn't already exist and returns the connection to that database for you to use.
        SQLiteConnection CreateConnection()
        {

            SQLiteConnection sqlite_conn;
            // Create a new database connection:
            sqlite_conn = new SQLiteConnection("Data Source=RPIIInspections.db; Version = 3; New = True; Compress = True; ");
            // Open the connection:
            try
            {
                sqlite_conn.Open();
            }
            catch (Exception ex)
            {

            }
            return sqlite_conn;
        }

        /*
        Creates the table if it doesn't already exist. 
        I probably should have just made the table manually and packaged it with the tool, 
        but this at least allows me to be flexible in the future if anything changes and update the table via code, instead of manual edits directly using a third party app.
        Speaking of third party apps - If you need one for sqlite then use "DB Browser (SQLite)" from here: https://sqlitebrowser.org/
        It was pretty useful, visual, free and open-source!
        */
        void CreateTable(SQLiteConnection conn)
        {
            try
            {
                SQLiteCommand sqlite_cmd;
                string Createsql =

                    "CREATE TABLE IF NOT EXISTS Inspections (" +
                    //Global Details
                    "TagID INTEGER PRIMARY KEY," +
                    "image TEXT," +
                    "inspectionCompany TEXT," +
                    "inspectionDate TEXT," +
                    "RPIIRegNum TEXT," +
                    "placeInspected TEXT," +

                    //Unit Details Tab
                    "unitDescription TEXT," +
                    "unitManufacturer TEXT," +
                    "unitWidth REAL," +
                    "unitLength REAL," +
                    "unitHeight REAL," +
                    "serial TEXT," +
                    "unitType TEXT," +
                    "unitOwner TEXT," +          

                    //User Height/Count Tab
                    "containingWallHeight REAL," +
                    "containingWallHeightComment TEXT," +
                    "platformHeight REAL," +
                    "platformHeightComment TEXT," +
                    "slideBarrierHeight REAL," +
                    "slideBarrierHeightComment TEXT," +
                    "remainingSlideWallHeight REAL," +
                    "remainingSlideWallHeightComment TEXT," +
                    "permanentRoof INTEGER," +
                    "permanentRoofComment TEXT," +
                    "userHeight REAL," +
                    "userHeightComment TEXT," +
                    "playAreaLength REAL," +
                    "playAreaLengthComment TEXT," +
                    "playAreaWidth REAL," +
                    "playAreaWidthComment TEXT," +
                    "negAdjustment REAL," +
                    "negAdjustmentComment TEXT," +
                    "usersat1000mm INTEGER," +
                    "usersat1200mm INTEGER," +
                    "usersat1500mm INTEGER," +
                    "usersat1800mm INTEGER," +

                    //Slide Tab
                    "isSlideChk INTEGER," +
                    "slidePlatformHeight REAL," +
                    "slidePlatformHeightComment TEXT," +
                    "slideWallHeight REAL," +
                    "slideWallHeightComment TEXT," +
                    "slideFirstMetreHeight REAL," +
                    "slideFirstMetreHeightComment TEXT," +
                    "slideBeyondFirstMetreHeight REAL," +
                    "slideBeyondFirstMetreHeightComment TEXT," +
                    "slidePermanentRoof INTEGER," +
                    "slidePermanentRoofComment TEXT," +
                    "clamberNettingPass INTEGER," +
                    "clamberNettingComment TEXT," +
                    "runoutValue REAL," +
                    "runoutPass INTEGER," +
                    "runoutComment TEXT," +
                    "slipSheetPass INTEGER," +
                    "slipSheetComment TEXT," +

                    //Structure Tab
                    "seamIntegrityPass INTEGER," +
                    "seamIntegrityComment TEXT," +
                    "lockStitchPass INTEGER," +
                    "lockStitchComment TEXT," +
                    "stitchLength INTEGER," +
                    "stitchLengthPass INTEGER," +
                    "stitchLengthComment TEXT," +
                    "airLossPass INTEGER," +
                    "airLossComment TEXT," +
                    "straightWallsPass INTEGER," +
                    "straightWallsComment TEXT," +
                    "sharpEdgesPass INTEGER," +
                    "sharpEdgesComment TEXT," +
                    "blowerTubeLength REAL," +
                    "blowerTubeLengthPass INTEGER," +
                    "blowerTubeLengthComment TEXT," +
                    "unitStablePass INTEGER," +
                    "unitStableComment TEXT," +
                    "evacTime INTEGER," +
                    "evacTimePass INTEGER," +
                    "evacTimeComment TEXT," +
                    "stepSizeValue REAL," +
                    "stepSizePass INTEGER," +
                    "stepSizeComment TEXT," +
                    "falloffHeightValue REAL," +
                    "falloffHeightPass INTEGER," +
                    "falloffHeightComment TEXT," +
                    "unitPressureValue REAL," +
                    "unitPressurePass INTEGER," +
                    "unitPressureComment TEXT," +
                    "troughDepthValue REAL," +
                    "troughWidthValue REAL," +
                    "troughPass INTEGER," +
                    "troughComment TEXT," +
                    "entrapPass INTEGER," +
                    "entrapComment TEXT," +
                    "markingsPass INTEGER," +
                    "markingsComment TEXT," +
                    "groundingPass INTEGER," +
                    "groundingComment TEXT," +

                    //Anchorage
                    "numLowAnchors INTEGER," +
                    "numHighAnchors INTEGER," +
                    "numAnchorsPass INTEGER," +
                    "numAnchorsComment TEXT," +
                    "anchorAccessoriesPass INTEGER," +
                    "anchorAccessoriesComment TEXT," +
                    "anchorDegreePass INTEGER," +
                    "anchorDegreeComment TEXT," +
                    "anchorTypePass INTEGER," +
                    "anchorTypeComment TEXT," +
                    "pullStrengthPass INTEGER," +
                    "pullStrengthComment TEXT," +

                    //Totally Enclosed Tab
                    "isUnitEnclosedChk INTEGER," +
                    "exitNumber INTEGER," +
                    "exitNumberPass INTEGER," +
                    "exitNumberComment TEXT," +
                    "exitVisiblePass INTEGER," +
                    "exitVisibleComment TEXT," +

                    //Materials Tab
                    "ropeSize INTEGER," +
                    "ropeSizePass INTEGER," +
                    "ropeSizeComment TEXT," +
                    "clamberPass INTEGER," +
                    "clamberComment TEXT," +
                    "retentionNettingPass INTEGER," +
                    "retentionNettingComment TEXT," +
                    "zipsPass INTEGER," +
                    "zipsComment TEXT," +
                    "windowsPass INTEGER," +
                    "windowsComment TEXT," +
                    "artworkPass INTEGER," +
                    "artworkComment TEXT," +
                    "threadPass INTEGER," +
                    "threadComment TEXT," +
                    "fabricPass INTEGER," +
                    "fabricComment TEXT," +
                    "fireRetardentPass INTEGER," +
                    "fireRetardentComment TEXT," +

                    //Fan Tab
                    "fanSizeComment TEXT," +
                    "blowerFlapPass INTEGER," +
                    "blowerFlapComment TEXT," +
                    "blowerFingerPass INTEGER," +
                    "blowerFingerComment TEXT," +
                    "patPass INTEGER," +
                    "patComment TEXT," +
                    "blowerVisualPass INTEGER," +
                    "blowerVisualComment TEXT," +
                    "blowerSerial TEXT," +

                    //Risk Assessment Tab
                    "riskAssessment TEXT," +

                    //Passed or not plus testimony
                    "passed INTEGER," +
                    "Testimony TEXT," +

                    //Additional Images
                    "AdditionalImage1 TEXT," +
                    "AdditionalImage2 TEXT," +
                    "AdditionalImage3 TEXT," +
                    "AdditionalImage4 TEXT," +

                    //Operator Manual
                    "operatorManual INTEGER," +

                    //Bungee Run
                    "isBungee INTEGER," +
                    "bungeeBlowerForwardDistancePass INTEGER," +
                    "bungeeBlowerForwardDistanceComment TEXT," +
                    "bungeeMarkingMaxMassPass INTEGER," +
                    "bungeeMarkingMaxMassComment TEXT," +
                    "bungeeMarkingMinHeightPass INTEGER," +
                    "bungeeMarkingMinHeightComment TEXT," +
                    "bungeePullStrengthPass INTEGER," +
                    "bungeePullStrengthComment TEXT," +
                    "bungeeCordLengthMaxPass INTEGER," +
                    "bungeeCordLengthMaxComment TEXT," +
                    "bungeeCordDiametreMinPass INTEGER," +
                    "bungeeCordDiametreMinComment TEXT," +
                    "bungeeTwoStageLockingPass INTEGER," +
                    "bungeeTwoStageLockingComment TEXT," +
                    "bungeeBatonCompliantPass INTEGER," +
                    "bungeeBatonCompliantComment TEXT," +
                    "bungeeLaneWidthMaxPass INTEGER," +
                    "bungeeLaneWidthMaxComment TEXT," +
                    "bungeeHarnessWidth INTEGER," +
                    "bungeeHarnessWidthPass INTEGER," +
                    "bungeeHarnessWidthComment TEXT," +
                    "bungeeNumOfCords INTEGER," +
                    "bungeeRearWallThicknessValue REAL," +
                    "bungeeRearWallHeightValue REAL," +
                    "bungeeRearWallPass INTEGER," +
                    "bungeeRearWallComment TEXT," +
                    "bungeeSideWallLengthValue REAL," +
                    "bungeeSideWallHeightValue REAL," +
                    "bungeeSideWallPass INTEGER," +
                    "bungeeSideWallComment TEXT," +
                    "bungeeRunningWallWidthValue REAL," +
                    "bungeeRunningWallHeightValue REAL," +
                    "bungeeRunningWallPass INTEGER," +
                    "bungeeRunningWallComment TEXT," +

                    //Toddler Zone / Play Zone
                    "playZoneIsPlayZoneChk INTEGER," +
                    "playZoneAgeMarkingChk INTEGER," +
                    "playZoneAgeMarkingComment TEXT," +
                    "playZoneHeightMarkingChk INTEGER," +
                    "playZoneHeightMarkingComment TEXT," +
                    "playZoneSightLineChk INTEGER," +
                    "playZoneSightLineComment TEXT," +
                    "playZoneAccessChk INTEGER," +
                    "playZoneAccessComment TEXT," +
                    "playZoneSuitableMattingChk INTEGER," +
                    "playZoneSuitableMattingComment TEXT," +
                    "playZoneTrafficChk INTEGER," +
                    "playZoneTrafficFlowComment TEXT," +
                    "playZoneAirJugglerChk INTEGER," +
                    "playZoneAirJugglerComment TEXT," +
                    "playZoneBallsChk INTEGER," +
                    "playZoneBallsComment TEXT," +
                    "playZoneBallPoolGapsChk INTEGER," +
                    "playZoneBallPoolGapsComment TEXT," +
                    "playZoneFittedSheetChk INTEGER," +
                    "playZoneFittedSheetComment TEXT," +
                    "playZoneBallPoolDepthValue INTEGER," +
                    "playZoneBallPoolDepthChk INTEGER," +
                    "playZoneBallPoolDepthComment TEXT," +
                    "playZoneBallPoolEntryHeightValue INTEGER," +
                    "playZoneBallPoolEntryHeightChk INTEGER," +
                    "playZoneBallPoolEntryHeightComment TEXT," +
                    "playZoneSlideGradValue INTEGER," +
                    "playZoneSlideGradChk INTEGER," +
                    "playZoneSlideGradComment TEXT," +
                    "playZoneSlidePlatHeightValue REAL," +
                    "playZoneSlidePlatHeightChk INTEGER," +
                    "playZoneSlidePlatHeightComment TEXT," +

                    //Inflatable Ball Pool
                    "isToddlerBallPoolChk INTEGER," +
                    "tbpAgeRangeMarkingChk INTEGER," +
                    "tbpAgeRangeMarkingComment TEXT," +
                    "tblMaxHeightMarkingsChk INTEGER," +
                    "tpbMaxHeightMarkingsComment TEXT," +
                    "tbpSuitableMattingChk INTEGER," +
                    "tbpSuitableMattingComment TEXT," +
                    "tbpAirJugglersCompliantChk INTEGER," +
                    "tbpAirJugglersCompliantComment TEXT," +
                    "tbpBallsCompliantChk INTEGER," +
                    "tbpBallsCompliantComment TEXT," +
                    "tbpGapsChk INTEGER," +
                    "tbpGapsComment TEXT," +
                    "tbpFittedBaseChk INTEGER," +
                    "tbpFittedBaseComment TEXT," +
                    "tbpBallPoolDepthValue INTEGER," +
                    "tbpBallPoolDepthChk INTEGER," +
                    "tbpBallPoolDepthComment TEXT," +
                    "tbpBallPoolEntryValue INTEGER," +
                    "tbpBallPoolEntryChk INTEGER," +
                    "tbpBallPoolEntryComment TEXT," +

                    //Indoor Use Only
                    "indoorOnlyChk INTEGER," +

                    //Inflatable Games
                    "isInflatableGameChk INTEGER," +
                    "gameTypeComment TEXT," +
                    "gameMaxUserMassChk INTEGER," +
                    "gameMaxUserMassComment TEXT," +
                    "gameAgeRangeMarkingChk INTEGER," +
                    "gameAgeRangeMarkingComment TEXT," +
                    "gameConstantAirFlowChk INTEGER," +
                    "gameConstantAirFlowComment TEXT," +
                    "gameDesignRiskChk INTEGER," +
                    "gameDesignRiskComment TEXT," +
                    "gameIntendedPlayRiskChk INTEGER," +
                    "gameIntendedPlayRiskComment TEXT," +
                    "gameAncillaryEquipmentChk INTEGER," +
                    "gameAncillaryEquipmentComment TEXT," +
                    "gameAncillaryEquipmentCompliantChk INTEGER," +
                    "gameAncillaryEquipmentCompliantComment TEXT," +
                    "gameContainingWallHeightValue REAL," +
                    "gameContainingWallHeightChk INTEGER," +
                    "gameContainingWallHeightComment TEXT," +

                    //Catch Bed
                    "isCatchBedChk INTEGER," +
                    "catchbedTypeOfUnitComment TEXT," +
                    "catchbedMaxUserMassMarkingChk INTEGER," +
                    "catchbedMaxUserMassMarkingComment TEXT," +
                    "catchbedArrestChk INTEGER," +
                    "catchbedArrestComment TEXT," +
                    "catchbedMattingChk INTEGER," +
                    "catchbedMattingComment TEXT," +
                    "catchbedDesignRiskChk INTEGER," +
                    "catchbedDesignRiskComment TEXT," +
                    "catchbedIntendedPlayChk INTEGER," +
                    "catchbedIntendedPlayRiskComment TEXT," +
                    "catchbedAncillaryFitChk INTEGER," +
                    "catchbedAncillaryFitComment TEXT," +
                    "catchbedAncillaryCompliantChk INTEGER," +
                    "catchbedAncillaryCompliantComment TEXT," +
                    "catchbedApronChk INTEGER," +
                    "catchbedApronComment TEXT," +
                    "catchbedTroughChk INTEGER," +
                    "catchbedTroughDepthComment TEXT," +
                    "catchbedFrameworkChk INTEGER," +
                    "catchbedFrameworkComment TEXT," +
                    "catchbedGroundingChk INTEGER," +
                    "catchbedGroundingComment TEXT," +
                    "catchbedBedHeightValue INTEGER," +
                    "catchbedBedHeightChk INTEGER," +
                    "catchbedBedHeightComment TEXT," +
                    "catchbedPlatformFallDistanceValue REAL," +
                    "catchbedPlatformFallDistanceChk INTEGER," +
                    "catchbedPlatformFallDistanceComment TEXT," +
                    "catchbedBlowerTubeLengthValue REAL," +
                    "catchbedBlowerTubeLengthChk INTEGER," +
                    "catchbedBlowerTubeLengthComment TEXT" +

                    ");";

                sqlite_cmd = conn.CreateCommand();

                sqlite_cmd.CommandText = Createsql;
                sqlite_cmd.ExecuteNonQuery();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), toolName);
            }
        }

        /*
         *Have you ever seen a longer formatted query in your life? Jesus Christ...
         *I couldn't write this on auto-pilot, I had to concentrate as one wrong error doesn't provide a very helpful error message.
        */


        void InsertData(SQLiteConnection conn)
        {
            SQLiteCommand sqlite_cmd = conn.CreateCommand();

            string image = ConvertImageToString(compressImage(unitPic.Image, (double)400, (double)400));
            string inspectionCompany = sanitiseSQL(InspectionCompName.Text);
            string inspectionDate = datePicker.Value.ToLongDateString();
            string RPIIRegNum = rpiiReg.Text;
            string placeInspected = sanitiseSQL(inspectionLocation.Text);
            string unitDescription = sanitiseSQL(unitDescriptionText.Text);
            string unitManufacturer = sanitiseSQL(ManufacturerText.Text);
            string unitWidth = unitWidthNum.Value.ToString();
            string unitLength = unitLengthNum.Value.ToString();
            string unitHeight = unitHeightNum.Value.ToString();
            string serial = sanitiseSQL(serialText.Text);
            string unitType = sanitiseSQL(unitTypeText.Text);
            string unitOwner = sanitiseSQL(unitOwnerText.Text);
            string containingWallHeight = containingWallHeightValue.Value.ToString();
            string containingWallHeightCommentText = sanitiseSQL(containingWallHeightComment.Text);
            string platformHeight = platformHeightValue.Value.ToString();
            string platformHeightCommentText = sanitiseSQL(platformHeightComment.Text);
            string slideBarrierHeight = slidebarrierHeightValue.Value.ToString();
            string slideBarrierHeightCommentText = sanitiseSQL(slideBarrierHeightComment.Text);
            string remainingSlideWallHeight = remainingSlideWallHeightValue.Value.ToString();
            string remainingSlideWallHeightCommentText = sanitiseSQL(remainingSlideWallHeightComment.Text);
            string permanentRoof = permanentRoofChecked.Checked.ToString();
            string permanentRoofCommentText = sanitiseSQL(permRoofComment.Text);
            string userHeightValue = userHeight.Value.ToString();
            string userHeightCommentText = sanitiseSQL(userHeightComment.Text);
            string playAreaLength = playAreaLengthValue.Value.ToString();
            string playAreaLengthCommentText = sanitiseSQL(playAreaLengthComment.Text);
            string playAreaWidth = playAreaWidthValue.Value.ToString();
            string playAreaWidthCommentText = sanitiseSQL(playAreaWidthComment.Text);
            string playAreaNegAdj = negAdjustmentValue.Value.ToString();
            string playAreaNedAdjCommentText = sanitiseSQL(negAdjustmentComment.Text);
            string numUsersat1000mm = usersat1000mm.Value.ToString();
            string numUsersat1200mm = usersat1200mm.Value.ToString();
            string numUsersat1500mm = usersat1500mm.Value.ToString();
            string numUsersat1800mm = usersat1800mm.Value.ToString();
            string isSlideChkPass = isSlideChk.Checked.ToString();
            string slidePlatformHeight = slidePlatformHeightValue.Value.ToString();
            string slidePlatformHeightCommentText = sanitiseSQL(slidePlatformHeightComment.Text);
            string slideWallHeight = slideWallHeightValue.Value.ToString();
            string slideWallHeightCommentText = sanitiseSQL(slideWallHeightComment.Text);
            string slideFirstMetreHeight = slidefirstmetreHeightValue.Value.ToString();
            string slideFirstMetreHeightCommentText = sanitiseSQL(slideFirstMetreHeightComment.Text);
            string slideBeyondFirstMetreHeight = beyondfirstmetreHeightValue.Value.ToString();
            string beyondfirstmetreHeightCommentText = sanitiseSQL(beyondfirstmetreHeightComment.Text);
            string slidePermRoof = slidePermRoofedCheck.Checked.ToString();
            string slidePermRoofCommentText = sanitiseSQL(slidePermRoofedComment.Text);
            string clamberNettingPass = clamberNettingPassFail.Checked.ToString();
            string clamberNettingCommentText = sanitiseSQL(clamberNettingComment.Text);
            string runout = runoutValue.Value.ToString();
            string runoutPass = runOutPassFail.Checked.ToString();
            string runoutCommentText = sanitiseSQL(runoutComment.Text);
            string slipsheetPass = slipsheetPassFail.Checked.ToString();
            string slipsheetCommentText = sanitiseSQL(slipsheetComment.Text);
            string seamIntegrityPass = seamIntegrityPassFail.Checked.ToString();
            string seamIntegrityCommentText = sanitiseSQL(seamIntegrityComment.Text);
            string lockStitchPass = lockstitchPassFail.Checked.ToString();
            string lockStitchCommentText = sanitiseSQL(lockStitchComment.Text);
            string stitchLength = stitchLengthValue.Value.ToString();
            string stitchLengthPass = stitchLengthPassFail.Checked.ToString();
            string stitchLengthCommentText = sanitiseSQL(stitchLengthComment.Text);
            string airLoss = airLossPassFail.Checked.ToString();
            string airLossCommentText = sanitiseSQL(airLossComment.Text);
            string straightWalls = wallStraightPassFail.Checked.ToString();
            string straightWallsComment = sanitiseSQL(wallStraightComment.Text);
            string sharpEdgesPass = sharpEdgesPassFail.Checked.ToString();
            string sharpEdgesCommentText = sanitiseSQL(sharpEdgesComment.Text);
            string blowerTubeLengthValue = tubeDistanceValue.Value.ToString();
            string blowerTubeLengthPass = tubeDistancePassFail.Checked.ToString();
            string blowerTubeLengthCommentText = sanitiseSQL(tubeDistanceComment.Text);
            string unitStablePass = stablePassFail.Checked.ToString();
            string unitStableComment = sanitiseSQL(stableComment.Text);
            string evacTimeValue = evacTime.Value.ToString();
            string evacTimePass = evacTimePassFail.Checked.ToString();
            string evacTimeCommentText = sanitiseSQL(evacTimeComment.Text);
            string stepSize = stepSizeValue.Value.ToString();
            string stepSizePass = stepSizePassFail.Checked.ToString();
            string stepSizeCommentText = sanitiseSQL(stepSizeComment.Text);
            string falloffHeightValue = falloffHeight.Value.ToString();
            string falloffHeightPass = falloffHeightPassFail.Checked.ToString();
            string falloffHeightCommentText = sanitiseSQL(falloffHeightComment.Text);
            string pressureVal = pressureValue.Value.ToString();
            string pressurePass = pressurePassFail.Checked.ToString();
            string pressureCommentText = sanitiseSQL(pressureComment.Text);
            string troughDepth = troughDepthValue.Value.ToString();
            string troughWidth = troughWidthValue.Value.ToString();
            string troughPass = troughPassFail.Checked.ToString();
            string troughDepthComment = sanitiseSQL(troughComment.Text);
            string entrapPass = entrapPassFail.Checked.ToString();
            string entrapPassComment = sanitiseSQL(entrapComment.Text);
            string markings = markingsPassFail.Checked.ToString();
            string markingCommentText = sanitiseSQL(markingsComment.Text);
            string groundingPass = groundingPassFail.Checked.ToString();
            string groundingCommentText = sanitiseSQL(groundingComment.Text);
            string numLowAnchorsValue = numLowAnchors.Value.ToString();
            string numHighAnchorsValue = numHighAnchors.Value.ToString();
            string numAnchorsPass = numAnchorsPassFail.Checked.ToString();
            string numAnchorsCommentText = sanitiseSQL(numAnchorsComment.Text);
            string anchorAccessoriesPass = anchorAccessoriesPassFail.Checked.ToString();
            string anchorAccessoriesCommentText = sanitiseSQL(AnchorAccessoriesComment.Text);
            string anchorDegreesPass = anchorDegreePassFail.Checked.ToString();
            string anchorDegreesCommentText = sanitiseSQL(anchorDegreesComment.Text);
            string anchorTypePass = anchorTypePassFail.Checked.ToString();
            string anchorTypeCommentText = sanitiseSQL(anchorTypeComment.Text);
            string pullStrengthPass = pullStrengthPassFail.Checked.ToString();
            string pullStrengthCommentText = sanitiseSQL(pullStrengthComment.Text);
            string isUnitEnclosedChkPass = isUnitEnclosedChk.Checked.ToString();
            string exitNumber = exitNumberValue.Value.ToString();
            string exitNumberPass = exitNumberPassFail.Checked.ToString();
            string exitNumberCommentText = sanitiseSQL(exitNumberComment.Text);
            string exitVisiblePass = exitsignVisiblePassFail.Checked.ToString();
            string exitVisibleCommentText = sanitiseSQL(exitSignVisibleComment.Text);
            string ropeSize = ropesizeValue.Value.ToString();
            string ropeSizePass = ropeSizePassFail.Checked.ToString();
            string ropeSizeCommentText = sanitiseSQL(ropeSizeComment.Text);
            string clamberPass = clamberPassFail.Checked.ToString();
            string clamberCommentText = sanitiseSQL(clamberComment.Text);
            string retentionNettingPass = retentionNettingPassFail.Checked.ToString();
            string retentionNettingCommentText = sanitiseSQL(retentionNettingComment.Text);
            string zipsPass = zipsPassFail.Checked.ToString();
            string zipsCommentText = sanitiseSQL(zipsComment.Text);
            string windowsPass = windowsPassFail.Checked.ToString();
            string windowsCommentText = sanitiseSQL(windowsComment.Text);
            string artworkPass = artworkPassFail.Checked.ToString();
            string artworkCommentText = sanitiseSQL(artworkComment.Text);
            string threadPass = threadPassFail.Checked.ToString();
            string threadCommentText = sanitiseSQL(threadComment.Text);
            string fabricPass = fabricPassFail.Checked.ToString();
            string fabricCommentText = sanitiseSQL(fabricComment.Text);
            string fireRetardentPass = fireRetardentPassFail.Checked.ToString();
            string fireRetardentCommentText = sanitiseSQL(fireRetardentComment.Text);
            string fanSizeCommentText = sanitiseSQL(blowerSizeComment.Text);
            string blowerFlapPass = blowerFlapPassFail.Checked.ToString();
            string blowerFlapCommentText = sanitiseSQL(blowerFlapComment.Text);
            string blowerFingerPass = blowerFingerPassFail.Checked.ToString();
            string blowerFingerCommentText = sanitiseSQL(blowerFingerComment.Text);
            string patPass = patPassFail.Checked.ToString();
            string patCommentText = sanitiseSQL(patComment.Text);
            string blowerVisualPass = blowerVisualPassFail.Checked.ToString();
            string blowerVisualCommentText = sanitiseSQL(blowerVisualComment.Text);
            string blowerSerialText = sanitiseSQL(blowerSerial.Text);

            string riskAssessment = sanitiseSQL(riskAssessmentNotes.Text);
            string passed = passedRadio.Checked.ToString();

            string testimonyText = sanitiseSQL(testimony.Text);

            string adImg1 = ConvertImageToString(compressImage(AdditionalPic1.Image, (double)400, (double)400));
            string adImg2 = ConvertImageToString(compressImage(AdditionalPic2.Image, (double)400, (double)400));
            string adImg3 = ConvertImageToString(compressImage(AdditionalPic3.Image, (double)400, (double)400));
            string adImg4 = ConvertImageToString(compressImage(AdditionalPic4.Image, (double)400, (double)400));

            string operatorManual = operatorManualChk.Checked.ToString();

            //Bungee
            string isBungee = isBungeeRunChk.Checked.ToString();
            string bungeeBlowerForwardDistancePass = bungeeBlowerDistanceChk.Checked.ToString();
            string bungeeBlowerForwardDistanceComment = bungeeBlowerDistanceComment.Text.ToString();
            string bungeeMarkingMaxMassPass = bungeeMaxMassChk.Checked.ToString();
            string bungeeMarkingMaxMassComment = bungeeUserMaxMassComment.Text.ToString();
            string bungeeMarkingMinHeightPass = bungeeMinHeightChk.Checked.ToString();
            string bungeeMarkingMinHeightComment = bungeeMinHeightComment.Text.ToString();
            string bungeePullStrengthPass = bungeePullTestChk.Checked.ToString();
            string bungeePullStrengthComment = bungeeHarnessPullTestComment.Text.ToString();
            string bungeeCordLengthMaxPass = bungeeCordLengthChk.Checked.ToString();
            string bungeeCordLengthMaxComment = bungeeCordLengthComment.Text.ToString();
            string bungeeCordDiametreMinPass = bungeeCordDiametreChk.Checked.ToString();
            string bungeeCordDiametreMinComment = bungeeCordDiametreComment.Text.ToString();
            string bungeeTwoStageLockingPass = bungeeTwoStageChk.Checked.ToString();
            string bungeeTwoStageLockingComment = bungeeTwoStageComment.Text.ToString();
            string bungeeBatonCompliantPass = bungeeBatonCompliantChk.Checked.ToString();
            string bungeeRunBatonCompliantComment = bungeeBatonCompliantComment.Text.ToString();
            string bungeeLaneWidthMaxPass = bungeeLaneWidthChk.Checked.ToString();
            string bungeeLaneWidthMaxComment = bungeeLaneWidthComment.Text.ToString();
            string bungeeRunHarnessWidth = bungeeHarnessWidth.Value.ToString();
            string bungeeHarnessWidthPass = bungeeHarnessWidthPassChk.Checked.ToString();
            string bungeeRunHarnessWidthComment = bungeeHarnessWidthComment.Text.ToString();
            string bungeeNumOfCords = bungeeCordAmount.Value.ToString();
            string bungeeRearWallThicknessValue = bungeeRearWallWidthNum.Value.ToString();
            string bungeeRearWallHeightValue = bungeeRearWallHeight.Value.ToString();
            string bungeeRearWallPass = bungeeRearWallChk.Checked.ToString();
            string bungeeRunRearWallComment = bungeeRearWallComment.Text.ToString();
            string bungeeRunSideWallLengthValue = bungeeStartingPosWallsLengthNum.Value.ToString();
            string bungeeSideWallHeightValue = bungeeStartingPosWallsHeightNum.Value.ToString();
            string bungeeSideWallPass = bungeeStartingPosWallChk.Checked.ToString();
            string bungeeSideWallComment = bungeeStartingPosWallsComment.Text.ToString();
            string bungeeRunningWallWidthValue = bungeeRunningWallWidthNum.Value.ToString();
            string bungeeRunRunningWallHeightNum = bungeeRunningWallHeightNum.Value.ToString();
            string bungeeRunningWallPass = bungeeRunningWallChk.Checked.ToString();
            string bungeeRunRunningWallComment = bungeeRunningWallComment.Text.ToString();

            //PlayZone
            string playZoneIsPlayZoneChkPass = playZoneIsPlayZoneChk.Checked.ToString();
            string playZoneAgeMarkingChkPass = playZoneAgeMarkingChk.Checked.ToString();
            string playZoneAgeMarkingCommentText = playZoneAgeMarkingComment.Text.ToString();
            string playZoneHeightMarkingChkPass = playZoneHeightMarkingChk.Checked.ToString();
            string playZoneHeightMarkingCommentText = playZoneHeightMarkingComment.Text.ToString();
            string playZoneSightLineChkPass = playZoneSightLineChk.Checked.ToString();
            string playZoneSightLineCommentText = playZoneSightLineComment.Text.ToString();
            string playZoneAccessChkPass = playZoneAccessChk.Checked.ToString();
            string playZoneAccessCommentText = playZoneAccessComment.Text.ToString();
            string playZoneSuitableMattingChkPass = playZoneSuitableMattingChk.Checked.ToString();
            string playZoneSuitableMattingCommentText = playZoneSuitableMattingComment.Text.ToString();
            string playZoneTrafficChkPass = playZoneTrafficChk.Checked.ToString();
            string playZoneTrafficFlowCommentText = playZoneTrafficFlowComment.Text.ToString();
            string playZoneAirJugglerChkPass = playZoneAirJugglerChk.Checked.ToString();
            string playZoneAirJugglerCommentText = playZoneAirJugglerComment.Text.ToString();
            string playZoneBallsChkPass = playZoneBallsChk.Checked.ToString();
            string playZoneBallsCommentText = playZoneBallsComment.Text.ToString();
            string playZoneBallPoolGapsChkPass = playZoneBallPoolGapsChk.Checked.ToString();
            string playZoneBallPoolGapsCommentText = playZoneBallPoolGapsComment.Text.ToString();
            string playZoneFittedSheetChkPass = playZoneFittedSheetChk.Checked.ToString();
            string playZoneFittedSheetCommentText = playZoneFittedSheetComment.Text.ToString();
            string playZoneBallPoolDepthValueValue = playZoneBallPoolDepthValue.Value.ToString();
            string playZoneBallPoolDepthChkPass = playZoneBallPoolDepthChk.Checked.ToString();
            string playZoneBallPoolDepthCommentText = playZoneBallPoolDepthComment.Text.ToString();
            string playZoneBallPoolEntryHeightValueValue = playZoneBallPoolEntryHeightValue.Value.ToString();
            string playZoneBallPoolEntryHeightChkPass = playZoneBallPoolEntryHeightChk.Checked.ToString();
            string playZoneBallPoolEntryHeightCommentText = playZoneBallPoolEntryHeightComment.Text.ToString();
            string playZoneSlideGradValueValue = playZoneSlideGradValue.Value.ToString();
            string playZoneSlideGradChkPass = playZoneSlideGradChk.Checked.ToString();
            string playZoneSlideGradCommentText = playZoneSlideGradComment.Text.ToString();
            string playZoneSlidePlatHeightValueValue = playZoneSlidePlatHeightValue.Value.ToString();
            string playZoneSlidePlatHeightChkPass = playZoneSlidePlatHeightChk.Checked.ToString();
            string playZoneSlidePlatHeightCommentText = playZoneSlidePlatHeightComment.Text.ToString();

            //Inflatable Ball Pool
            string isToddlerBallPoolChkPass = isToddlerBallPoolChk.Checked.ToString();
            string tbpAgeRangeMarkingChkPass = tbpAgeRangeMarkingChk.Checked.ToString();
            string tbpAgeRangeMarkingCommentText = tbpAgeRangeMarkingComment.Text.ToString();
            string tblMaxHeightMarkingsChkPass = tblMaxHeightMarkingsChk.Checked.ToString();
            string tpbMaxHeightMarkingsCommentText = tpbMaxHeightMarkingsComment.Text.ToString();
            string tbpSuitableMattingChkPass = tbpSuitableMattingChk.Checked.ToString();
            string tbpSuitableMattingCommentText = tbpSuitableMattingComment.Text.ToString();
            string tbpAirJugglersCompliantChkPass = tbpAirJugglersCompliantChk.Checked.ToString();
            string tbpAirJugglersCompliantCommentText = tbpAirJugglersCompliantComment.Text.ToString();
            string tbpBallsCompliantChkPass = tbpBallsCompliantChk.Checked.ToString();
            string tbpBallsCompliantCommentText = tbpBallsCompliantComment.Text.ToString();
            string tbpGapsChkPass = tbpGapsChk.Checked.ToString();
            string tbpGapsCommentText = tbpGapsComment.Text.ToString();
            string tbpFittedBaseChkPass = tbpFittedBaseChk.Checked.ToString();
            string tbpFittedBaseCommentText = tbpFittedBaseComment.Text.ToString();
            string tbpBallPoolDepthValueValue = tbpBallPoolDepthValue.Value.ToString();
            string tbpBallPoolDepthChkPass = tbpBallPoolDepthChk.Checked.ToString();
            string tbpBallPoolDepthCommentText = tbpBallPoolDepthComment.Text.ToString();
            string tbpBallPoolEntryValueValue = tbpBallPoolEntryValue.Value.ToString();
            string tbpBallPoolEntryChkPass = tbpBallPoolEntryChk.Checked.ToString();
            string tbpBallPoolEntryCommentText = tbpBallPoolEntryComment.Text.ToString();

            //Indoor Only
            string indoorOnlyChkPass = indoorOnlyChk.Checked.ToString();

            //Inflatable Games
            string isInflatableGameChkPass = isInflatableGameChk.Checked.ToString();
            string gameTypeCommentText = gameTypeComment.Text.ToString();
            string gameMaxUserMassChkPass = gameMaxUserMassChk.Checked.ToString();
            string gameMaxUserMassCommentText = gameMaxUserMassComment.Text.ToString();
            string gameAgeRangeMarkingChkPass = gameAgeRangeMarkingChk.Checked.ToString();
            string gameAgeRangeMarkingCommentText = gameAgeRangeMarkingComment.Text.ToString();
            string gameConstantAirFlowChkPass = gameConstantAirFlowChk.Checked.ToString();
            string gameConstantAirFlowCommentText = gameConstantAirFlowComment.Text.ToString();
            string gameDesignRiskChkPass = gameDesignRiskChk.Checked.ToString();
            string gameDesignRiskCommentText = gameDesignRiskComment.Text.ToString();
            string gameIntendedPlayRiskChkPass = gameIntendedPlayRiskChk.Checked.ToString();
            string gameIntendedPlayRiskCommentText = gameIntendedPlayRiskComment.Text.ToString();
            string gameAncillaryEquipmentChkPass = gameAncillaryEquipmentChk.Checked.ToString();
            string gameAncillaryEquipmentCommentText = gameAncillaryEquipmentComment.Text.ToString();
            string gameAncillaryEquipmentCompliantChkPass = gameAncillaryEquipmentCompliantChk.Checked.ToString();
            string gameAncillaryEquipmentCompliantCommentText = gameAncillaryEquipmentCompliantComment.Text.ToString();
            string gameContainingWallHeightValueValue = gameContainingWallHeightValue.Value.ToString();
            string gameContainingWallHeightChkPass = gameContainingWallHeightChk.Checked.ToString();
            string gameContainingWallHeightCommentText = gameContainingWallHeightComment.Text.ToString();

            //Catch bed
            string isCatchBedChkPass = isCatchBedChk.Checked.ToString();
            string catchbedTypeOfUnitCommentText = catchbedTypeOfUnitComment.Text.ToString();
            string catchbedMaxUserMassMarkingChkPass = catchbedMaxUserMassMarkingChk.Checked.ToString();
            string catchbedMaxUserMassMarkingCommentText = catchbedMaxUserMassMarkingComment.Text.ToString();
            string catchbedArrestChkPass = catchbedArrestChk.Checked.ToString();
            string catchbedArrestCommentText = catchbedArrestComment.Text.ToString();
            string catchbedMattingChkPass = catchbedMattingChk.Checked.ToString();
            string catchbedMattingCommentText = catchbedMattingComment.Text.ToString();
            string catchbedDesignRiskChkPass = catchbedDesignRiskChk.Checked.ToString();
            string catchbedDesignRiskCommentText = catchbedDesignRiskComment.Text.ToString();
            string catchbedIntendedPlayChkPass = catchbedIntendedPlayChk.Checked.ToString();
            string catchbedIntendedPlayRiskCommentText = catchbedIntendedPlayRiskComment.Text.ToString();
            string catchbedAncillaryFitChkPass = catchbedAncillaryFitChk.Checked.ToString();
            string catchbedAncillaryFitCommentText = catchbedAncillaryFitComment.Text.ToString();
            string catchbedAncillaryCompliantChkPass = catchbedAncillaryCompliantChk.Checked.ToString();
            string catchbedAncillaryCompliantCommentText = catchbedAncillaryCompliantComment.Text.ToString();
            string catchbedApronChkPass = catchbedApronChk.Checked.ToString();
            string catchbedApronCommentText = catchbedApronComment.Text.ToString();
            string catchbedTroughChkPass = catchbedTroughChk.Checked.ToString();
            string catchbedTroughDepthCommentText = catchbedTroughDepthComment.Text.ToString();
            string catchbedFrameworkChkPass = catchbedFrameworkChk.Checked.ToString();
            string catchbedFrameworkCommentText = catchbedFrameworkComment.Text.ToString();
            string catchbedGroundingChkPass = catchbedGroundingChk.Checked.ToString();
            string catchbedGroundingCommentText = catchbedGroundingComment.Text.ToString();
            string catchbedBedHeightValueValue = catchbedBedHeightValue.Value.ToString();
            string catchbedBedHeightChkPass = catchbedBedHeightChk.Checked.ToString();
            string catchbedBedHeightCommentText = catchbedBedHeightComment.Text.ToString();
            string catchbedPlatformFallDistanceValueValue = catchbedPlatformFallDistanceValue.Value.ToString();
            string catchbedPlatformFallDistanceChkPass = catchbedPlatformFallDistanceChk.Checked.ToString();
            string catchbedPlatformFallDistanceCommentText = catchbedPlatformFallDistanceComment.Text.ToString();
            string catchbedBlowerTubeLengthValueValue = catchbedBlowerTubeLengthValue.Value.ToString();
            string catchbedBlowerTubeLengthChkPass = catchbedBlowerTubeLengthChk.Checked.ToString();
            string catchbedBlowerTubeLengthCommentText = catchbedBlowerTubeLengthComment.Text.ToString();


            sqlite_cmd.CommandText =
                "INSERT INTO Inspections(" +
                "image," +
                "inspectionCompany," +
                "inspectionDate," +
                "RPIIRegNum," +
                "placeInspected," +
                "unitDescription," +
                "unitManufacturer," +
                "unitWidth," +
                "unitLength," +
                "unitHeight," +
                "serial," +
                "unitType," +
                "unitOwner," +
                "containingWallHeight," +
                "ContainingWallHeightComment," +
                "platformHeight," +
                "platformHeightComment," +
                "slideBarrierHeight," +
                "slideBarrierHeightComment," +
                "remainingSlideWallHeight," +
                "remainingSlideWallHeightComment," +
                "permanentRoof," +
                "permanentRoofComment," +
                "userHeight," +
                "userHeightComment," +
                "playAreaLength," +
                "playAreaLengthComment," +
                "playAreaWidth," +
                "playAreaWidthComment," +
                "negAdjustment," +
                "negAdjustmentComment," +
                "usersat1000mm," +
                "usersat1200mm," +
                "usersat1500mm," +
                "usersat1800mm," +
                "isSlideChk," +
                "slidePlatformHeight," +
                "slidePlatformHeightComment," +
                "slideWallHeight," +
                "SlideWallHeightComment," +
                "slideFirstMetreHeight," +
                "slideFirstMetreHeightComment," +
                "slideBeyondFirstMetreHeight," +
                "slideBeyondFirstMetreHeightComment," +
                "slidePermanentRoof," +
                "slidePermanentRoofComment," +
                "clamberNettingPass," +
                "clamberNettingComment," +
                "runoutValue," +
                "runoutPass," +
                "runoutComment," +
                "slipSheetPass," +
                "slipSheetComment," +
                "seamIntegrityPass," +
                "seamIntegrityComment," +
                "lockStitchPass," +
                "lockStitchComment," +
                "stitchLength," +
                "stitchLengthPass," +
                "stitchLengthComment," +
                "airLossPass," +
                "airLossComment," +
                "straightWallsPass," +
                "straightWallsComment," +
                "sharpEdgesPass," +
                "sharpEdgesComment," +
                "blowerTubeLength," +
                "blowerTubeLengthPass," +
                "blowerTubeLengthComment," +
                "unitStablePass," +
                "unitStableComment," +
                "evacTime," +
                "evacTimePass," +
                "evacTimeComment," +
                "stepSizeValue," +
                "stepSizePass," +
                "stepSizeComment," +
                "falloffHeightValue," +
                "falloffHeightPass," +
                "falloffHeightComment," +
                "unitPressureValue," +
                "unitPressurePass," +
                "unitPressureComment," +
                "troughDepthValue," +
                "troughWidthValue," +
                "troughPass," +
                "troughComment," +
                "entrapPass," +
                "entrapComment," +
                "markingsPass," +
                "markingsComment," +
                "groundingPass," +
                "groundingComment," +
                "numLowAnchors," +
                "numHighAnchors," +
                "numAnchorsPass," +
                "numAnchorsComment," +
                "anchorAccessoriesPass," +
                "anchorAccessoriesComment," +
                "anchorDegreePass," +
                "anchorDegreeComment," +
                "anchorTypePass," +
                "anchorTypeComment," +
                "pullStrengthPass," +
                "pullStrengthComment," +
                "isUnitEnclosedChk," +
                "exitNumber," +
                "exitNumberPass," +
                "exitNumberComment," +
                "exitVisiblePass," +
                "exitVisibleComment," +
                "ropeSize," +
                "ropeSizePass," +
                "ropeSizeComment," +
                "clamberPass," +
                "clamberComment," +
                "retentionNettingPass," +
                "retentionNettingComment," +
                "zipsPass," +
                "zipsComment," +
                "windowsPass," +
                "windowsComment," +
                "artworkPass," +
                "artworkComment," +
                "threadPass," +
                "threadComment," +
                "fabricPass," +
                "fabricComment," +
                "fireRetardentPass," +
                "fireRetardentComment," +
                "fanSizeComment," +
                "blowerFlapPass," +
                "blowerFlapComment," +
                "blowerFingerPass," +
                "blowerFingerComment," +
                "patPass," +
                "patComment," +
                "blowerVisualPass," +
                "blowerVisualComment," +
                "blowerSerial," +
                "riskAssessment," +
                "passed," +
                "Testimony," +
                "AdditionalImage1," +
                "AdditionalImage2," +
                "AdditionalImage3," +
                "AdditionalImage4," +
                "operatorManual," +

                "isBungee," +
                "bungeeBlowerForwardDistancePass," +
                "bungeeBlowerForwardDistanceComment," +
                "bungeeMarkingMaxMassPass," +
                "bungeeMarkingMaxMassComment," +
                "bungeeMarkingMinHeightPass," +
                "bungeeMarkingMinHeightComment," +
                "bungeePullStrengthPass," +
                "bungeePullStrengthComment," +
                "bungeeCordLengthMaxPass," +
                "bungeeCordLengthMaxComment," +
                "bungeeCordDiametreMinPass," +
                "bungeeCordDiametreMinComment," +
                "bungeeTwoStageLockingPass," +
                "bungeeTwoStageLockingComment," +
                "bungeeBatonCompliantPass," +
                "bungeeBatonCompliantComment," +
                "bungeeLaneWidthMaxPass," +
                "bungeeLaneWidthMaxComment," +
                "bungeeHarnessWidth," +
                "bungeeHarnessWidthPass," +
                "bungeeHarnessWidthComment," +
                "bungeeNumOfCords," +
                "bungeeRearWallThicknessValue," +
                "bungeeRearWallHeightValue," +
                "bungeeRearWallPass," +
                "bungeeRearWallComment," +
                "bungeeSideWallLengthValue," +
                "bungeeSideWallHeightValue," +
                "bungeeSideWallPass," +
                "bungeeSideWallComment," +
                "bungeeRunningWallWidthValue," +
                "bungeeRunningWallHeightValue," +
                "bungeeRunningWallPass," +
                "bungeeRunningWallComment," +

                "playZoneIsPlayZoneChk," +
                "playZoneAgeMarkingChk," +
                "playZoneAgeMarkingComment," +
                "playZoneHeightMarkingChk," +
                "playZoneHeightMarkingComment," +
                "playZoneSightLineChk," +
                "playZoneSightLineComment," +
                "playZoneAccessChk," +
                "playZoneAccessComment," +
                "playZoneSuitableMattingChk," +
                "playZoneSuitableMattingComment," +
                "playZoneTrafficChk," +
                "playZoneTrafficFlowComment," +
                "playZoneAirJugglerChk," +
                "playZoneAirJugglerComment," +
                "playZoneBallsChk," +
                "playZoneBallsComment," +
                "playZoneBallPoolGapsChk," +
                "playZoneBallPoolGapsComment," +
                "playZoneFittedSheetChk," +
                "playZoneFittedSheetComment," +
                "playZoneBallPoolDepthValue," +
                "playZoneBallPoolDepthChk," +
                "playZoneBallPoolDepthComment," +
                "playZoneBallPoolEntryHeightValue," +
                "playZoneBallPoolEntryHeightChk," +
                "playZoneBallPoolEntryHeightComment," +
                "playZoneSlideGradValue," +
                "playZoneSlideGradChk," +
                "playZoneSlideGradComment," +
                "playZoneSlidePlatHeightValue," +
                "playZoneSlidePlatHeightChk," +
                "playZoneSlidePlatHeightComment," +

                //Inflatable Ball Pool
                "isToddlerBallPoolChk," +
                "tbpAgeRangeMarkingChk," +
                "tbpAgeRangeMarkingComment," +
                "tblMaxHeightMarkingsChk," +
                "tpbMaxHeightMarkingsComment," +
                "tbpSuitableMattingChk," +
                "tbpSuitableMattingComment," +
                "tbpAirJugglersCompliantChk," +
                "tbpAirJugglersCompliantComment," +
                "tbpBallsCompliantChk," +
                "tbpBallsCompliantComment," +
                "tbpGapsChk," +
                "tbpGapsComment," +
                "tbpFittedBaseChk," +
                "tbpFittedBaseComment," +
                "tbpBallPoolDepthValue," +
                "tbpBallPoolDepthChk," +
                "tbpBallPoolDepthComment," +
                "tbpBallPoolEntryValue," +
                "tbpBallPoolEntryChk," +
                "tbpBallPoolEntryComment," +

                //Indoor Only
                "indoorOnlyChk," +

                //Inflatable Games
                "isInflatableGameChk," +
                "gameTypeComment," +
                "gameMaxUserMassChk," +
                "gameMaxUserMassComment," +
                "gameAgeRangeMarkingChk," +
                "gameAgeRangeMarkingComment," +
                "gameConstantAirFlowChk," +
                "gameConstantAirFlowComment," +
                "gameDesignRiskChk," +
                "gameDesignRiskComment," +
                "gameIntendedPlayRiskChk," +
                "gameIntendedPlayRiskComment," +
                "gameAncillaryEquipmentChk," +
                "gameAncillaryEquipmentComment," +
                "gameAncillaryEquipmentCompliantChk," +
                "gameAncillaryEquipmentCompliantComment," +
                "gameContainingWallHeightValue," +
                "gameContainingWallHeightChk," +
                "gameContainingWallHeightComment," +

                //Catch Bed
                "isCatchBedChk," +
                "catchbedTypeOfUnitComment," +
                "catchbedMaxUserMassMarkingChk," +
                "catchbedMaxUserMassMarkingComment," +
                "catchbedArrestChk," +
                "catchbedArrestComment," +
                "catchbedMattingChk," +
                "catchbedMattingComment," +
                "catchbedDesignRiskChk," +
                "catchbedDesignRiskComment," +
                "catchbedIntendedPlayChk," +
                "catchbedIntendedPlayRiskComment," +
                "catchbedAncillaryFitChk," +
                "catchbedAncillaryFitComment," +
                "catchbedAncillaryCompliantChk," +
                "catchbedAncillaryCompliantComment," +
                "catchbedApronChk," +
                "catchbedApronComment," +
                "catchbedTroughChk," +
                "catchbedTroughDepthComment," +
                "catchbedFrameworkChk," +
                "catchbedFrameworkComment," +
                "catchbedGroundingChk," +
                "catchbedGroundingComment," +
                "catchbedBedHeightValue," +
                "catchbedBedHeightChk," +
                "catchbedBedHeightComment," +
                "catchbedPlatformFallDistanceValue," +
                "catchbedPlatformFallDistanceChk," +
                "catchbedPlatformFallDistanceComment," +
                "catchbedBlowerTubeLengthValue," +
                "catchbedBlowerTubeLengthChk," +
                "catchbedBlowerTubeLengthComment" +

                ")" +
                "VALUES(" +
                "'" + image + "'," +
                "'" + inspectionCompany + "'," +
                "'" + inspectionDate + "'," +
                "'" + RPIIRegNum + "'," +
                "'" + placeInspected + "'," +
                "'" + unitDescription + "'," +
                "'" + unitManufacturer + "'," +
                "'" + unitWidth + "'," +
                "'" + unitLength + "'," +
                "'" + unitHeight + "'," +
                "'" + serial + "'," +
                "'" + unitType + "'," +
                "'" + unitOwner + "'," +
                "'" + containingWallHeight + "'," +
                "'" + containingWallHeightCommentText + "'," +
                "'" + platformHeight + "'," +
                "'" + platformHeightCommentText + "'," +
                "'" + slideBarrierHeight + "'," +
                "'" + slideBarrierHeightCommentText + "'," +
                "'" + remainingSlideWallHeight + "'," +
                "'" + remainingSlideWallHeightCommentText + "'," +
                "'" + permanentRoof + "'," +
                "'" + permanentRoofCommentText + "'," +
                "'" + userHeightValue + "'," +
                "'" + userHeightCommentText + "'," +
                "'" + playAreaLength + "'," +
                "'" + playAreaLengthCommentText + "'," +
                "'" + playAreaWidth + "'," +
                "'" + playAreaWidthCommentText + "'," +
                "'" + playAreaNegAdj + "'," +
                "'" + playAreaNedAdjCommentText + "'," +
                "'" + numUsersat1000mm + "'," +
                "'" + numUsersat1200mm + "'," +
                "'" + numUsersat1500mm + "'," +
                "'" + numUsersat1800mm + "'," +
                "'" + isSlideChkPass + "'," +
                "'" + slidePlatformHeight + "'," +
                "'" + slidePlatformHeightCommentText + "'," +
                "'" + slideWallHeight + "'," +
                "'" + slideWallHeightCommentText + "'," +
                "'" + slideFirstMetreHeight + "'," +
                "'" + slideFirstMetreHeightCommentText + "'," +
                "'" + slideBeyondFirstMetreHeight + "'," +
                "'" + beyondfirstmetreHeightCommentText + "'," +
                "'" + slidePermRoof + "'," +
                "'" + slidePermRoofCommentText + "'," +
                "'" + clamberNettingPass + "'," +
                "'" + clamberNettingCommentText + "'," +
                "'" + runout + "'," +
                "'" + runoutPass + "'," +
                "'" + runoutCommentText + "'," +
                "'" + slipsheetPass + "'," +
                "'" + slipsheetCommentText + "'," +
                "'" + seamIntegrityPass + "'," +
                "'" + seamIntegrityCommentText + "'," +
                "'" + lockStitchPass + "'," +
                "'" + lockStitchCommentText + "'," +
                "'" + stitchLength + "'," +
                "'" + stitchLengthPass + "'," +
                "'" + stitchLengthCommentText + "'," +
                "'" + airLoss + "'," +
                "'" + airLossCommentText + "'," +
                "'" + straightWalls + "'," +
                "'" + straightWallsComment + "'," +
                "'" + sharpEdgesPass + "'," +
                "'" + sharpEdgesCommentText + "'," +
                "'" + blowerTubeLengthValue + "'," +
                "'" + blowerTubeLengthPass + "'," +
                "'" + blowerTubeLengthCommentText + "'," +
                "'" + unitStablePass + "'," +
                "'" + unitStableComment + "'," +
                "'" + evacTimeValue + "'," +
                "'" + evacTimePass + "'," +
                "'" + evacTimeCommentText + "'," +
                "'" + stepSize + "'," +
                "'" + stepSizePass + "'," +
                "'" + stepSizeCommentText + "'," +
                "'" + falloffHeightValue + "'," +
                "'" + falloffHeightPass + "'," +
                "'" + falloffHeightCommentText + "'," +
                "'" + pressureVal + "'," +
                "'" + pressurePass + "'," +
                "'" + pressureCommentText + "'," +
                "'" + troughDepth + "'," +
                "'" + troughWidth + "'," +
                "'" + troughPass + "'," +
                "'" + troughDepthComment + "'," +
                "'" + entrapPass + "'," +
                "'" + entrapPassComment + "'," +
                "'" + markings + "'," +
                "'" + markingCommentText + "'," +
                "'" + groundingPass + "'," +
                "'" + groundingCommentText + "'," +
                "'" + numLowAnchorsValue + "'," +
                "'" + numHighAnchorsValue + "'," +
                "'" + numAnchorsPass + "'," +
                "'" + numAnchorsCommentText + "'," +
                "'" + anchorAccessoriesPass + "'," +
                "'" + anchorAccessoriesCommentText + "'," +
                "'" + anchorDegreesPass + "'," +
                "'" + anchorDegreesCommentText + "'," +
                "'" + anchorTypePass + "'," +
                "'" + anchorTypeCommentText + "'," +
                "'" + pullStrengthPass + "'," +
                "'" + pullStrengthCommentText + "'," +
                "'" + isUnitEnclosedChkPass + "'," +
                "'" + exitNumber + "'," +
                "'" + exitNumberPass + "'," +
                "'" + exitNumberCommentText + "'," +
                "'" + exitVisiblePass + "'," +
                "'" + exitVisibleCommentText + "'," +
                "'" + ropeSize + "'," +
                "'" + ropeSizePass + "'," +
                "'" + ropeSizeCommentText + "'," +
                "'" + clamberPass + "'," +
                "'" + clamberCommentText + "'," +
                "'" + retentionNettingPass + "'," +
                "'" + retentionNettingCommentText + "'," +
                "'" + zipsPass + "'," +
                "'" + zipsCommentText + "'," +
                "'" + windowsPass + "'," +
                "'" + windowsCommentText + "'," +
                "'" + artworkPass + "'," +
                "'" + artworkCommentText + "'," +
                "'" + threadPass + "'," +
                "'" + threadCommentText + "'," +
                "'" + fabricPass + "'," +
                "'" + fabricCommentText + "'," +
                "'" + fireRetardentPass + "'," +
                "'" + fireRetardentCommentText + "'," +
                "'" + fanSizeCommentText + "'," +
                "'" + blowerFlapPass + "'," +
                "'" + blowerFlapCommentText + "'," +
                "'" + blowerFingerPass + "'," +
                "'" + blowerFingerCommentText + "'," +
                "'" + patPass + "'," +
                "'" + patCommentText + "'," +
                "'" + blowerVisualPass + "'," +
                "'" + blowerVisualCommentText + "'," +
                "'" + blowerSerialText + "'," +
                "'" + riskAssessment + "'," +
                "'" + passed + "'," +
                "'" + testimonyText + "'," +
                "'" + adImg1 + "'," +
                "'" + adImg2 + "'," +
                "'" + adImg3 + "'," +
                "'" + adImg4 + "'," +
                "'" + operatorManual + "'," +

                "'" + isBungee + "'," +
                "'" + bungeeBlowerForwardDistancePass + "'," +
                "'" + bungeeBlowerForwardDistanceComment + "'," +
                "'" + bungeeMarkingMaxMassPass + "'," +
                "'" + bungeeMarkingMaxMassComment + "'," +
                "'" + bungeeMarkingMinHeightPass + "'," +
                "'" + bungeeMarkingMinHeightComment + "'," +
                "'" + bungeePullStrengthPass + "'," +
                "'" + bungeePullStrengthComment + "'," +
                "'" + bungeeCordLengthMaxPass + "'," +
                "'" + bungeeCordLengthMaxComment + "'," +
                "'" + bungeeCordDiametreMinPass + "'," +
                "'" + bungeeCordDiametreMinComment + "'," +
                "'" + bungeeTwoStageLockingPass + "'," +
                "'" + bungeeTwoStageLockingComment + "'," +
                "'" + bungeeBatonCompliantPass + "'," +
                "'" + bungeeRunBatonCompliantComment + "'," +
                "'" + bungeeLaneWidthMaxPass + "'," +
                "'" + bungeeLaneWidthMaxComment + "'," +
                "'" + bungeeRunHarnessWidth + "'," +
                "'" + bungeeHarnessWidthPass + "'," +
                "'" + bungeeRunHarnessWidthComment + "'," +
                "'" + bungeeNumOfCords + "'," +
                "'" + bungeeRearWallThicknessValue + "'," +
                "'" + bungeeRearWallHeightValue + "'," +
                "'" + bungeeRearWallPass + "'," +
                "'" + bungeeRunRearWallComment + "'," +
                "'" + bungeeRunSideWallLengthValue + "'," +
                "'" + bungeeSideWallHeightValue + "'," +
                "'" + bungeeSideWallPass + "'," +
                "'" + bungeeSideWallComment + "'," +
                "'" + bungeeRunningWallWidthValue + "'," +
                "'" + bungeeRunRunningWallHeightNum + "'," +
                "'" + bungeeRunningWallPass + "'," +
                "'" + bungeeRunRunningWallComment + "'," +

                "'" + playZoneIsPlayZoneChkPass + "'," +
                "'" + playZoneAgeMarkingChkPass + "'," +
                "'" + playZoneAgeMarkingCommentText + "'," +
                "'" + playZoneHeightMarkingChkPass + "'," +
                "'" + playZoneHeightMarkingCommentText + "'," +
                "'" + playZoneSightLineChkPass + "'," +
                "'" + playZoneSightLineCommentText + "'," +
                "'" + playZoneAccessChkPass + "'," +
                "'" + playZoneAccessCommentText + "'," +
                "'" + playZoneSuitableMattingChkPass + "'," +
                "'" + playZoneSuitableMattingCommentText + "'," +
                "'" + playZoneTrafficChkPass + "'," +
                "'" + playZoneTrafficFlowCommentText + "'," +
                "'" + playZoneAirJugglerChkPass + "'," +
                "'" + playZoneAirJugglerCommentText + "'," +
                "'" + playZoneBallsChkPass + "'," +
                "'" + playZoneBallsCommentText + "'," +
                "'" + playZoneBallPoolGapsChkPass + "'," +
                "'" + playZoneBallPoolGapsCommentText + "'," +
                "'" + playZoneFittedSheetChkPass + "'," +
                "'" + playZoneFittedSheetCommentText + "'," +
                "'" + playZoneBallPoolDepthValueValue + "'," +
                "'" + playZoneBallPoolDepthChkPass + "'," +
                "'" + playZoneBallPoolDepthCommentText + "'," +
                "'" + playZoneBallPoolEntryHeightValueValue + "'," +
                "'" + playZoneBallPoolEntryHeightChkPass + "'," +
                "'" + playZoneBallPoolEntryHeightCommentText + "'," +
                "'" + playZoneSlideGradValueValue + "'," +
                "'" + playZoneSlideGradChkPass + "'," +
                "'" + playZoneSlideGradCommentText + "'," +
                "'" + playZoneSlidePlatHeightValueValue + "'," +
                "'" + playZoneSlidePlatHeightChkPass + "'," +
                "'" + playZoneSlidePlatHeightCommentText + "'," +

                "'" + isToddlerBallPoolChkPass + "'," +
                "'" + tbpAgeRangeMarkingChkPass + "'," +
                "'" + tbpAgeRangeMarkingCommentText + "'," +
                "'" + tblMaxHeightMarkingsChkPass + "'," +
                "'" + tpbMaxHeightMarkingsCommentText + "'," +
                "'" + tbpSuitableMattingChkPass + "'," +
                "'" + tbpSuitableMattingCommentText + "'," +
                "'" + tbpAirJugglersCompliantChkPass + "'," +
                "'" + tbpAirJugglersCompliantCommentText + "'," +
                "'" + tbpBallsCompliantChkPass + "'," +
                "'" + tbpBallsCompliantCommentText + "'," +
                "'" + tbpGapsChkPass + "'," +
                "'" + tbpGapsCommentText + "'," +
                "'" + tbpFittedBaseChkPass + "'," +
                "'" + tbpFittedBaseCommentText + "'," +
                "'" + tbpBallPoolDepthValueValue + "'," +
                "'" + tbpBallPoolDepthChkPass + "'," +
                "'" + tbpBallPoolDepthCommentText + "'," +
                "'" + tbpBallPoolEntryValueValue + "'," +
                "'" + tbpBallPoolEntryChkPass + "'," +
                "'" + tbpBallPoolEntryCommentText + "'," +

                "'" + indoorOnlyChkPass + "'," +

                "'" + isInflatableGameChkPass + "'," +
                "'" + gameTypeCommentText + "'," +
                "'" + gameMaxUserMassChkPass + "'," +
                "'" + gameMaxUserMassCommentText + "'," +
                "'" + gameAgeRangeMarkingChkPass + "'," +
                "'" + gameAgeRangeMarkingCommentText + "'," +
                "'" + gameConstantAirFlowChkPass + "'," +
                "'" + gameConstantAirFlowCommentText + "'," +
                "'" + gameDesignRiskChkPass + "'," +
                "'" + gameDesignRiskCommentText + "'," +
                "'" + gameIntendedPlayRiskChkPass + "'," +
                "'" + gameIntendedPlayRiskCommentText + "'," +
                "'" + gameAncillaryEquipmentChkPass + "'," +
                "'" + gameAncillaryEquipmentCommentText + "'," +
                "'" + gameAncillaryEquipmentCompliantChkPass + "'," +
                "'" + gameAncillaryEquipmentCompliantCommentText + "'," +
                "'" + gameContainingWallHeightValueValue + "'," +
                "'" + gameContainingWallHeightChkPass + "'," +
                "'" + gameContainingWallHeightCommentText + "'," +


                "'" + isCatchBedChkPass + "'," +
                "'" + catchbedTypeOfUnitCommentText + "'," +
                "'" + catchbedMaxUserMassMarkingChkPass + "'," +
                "'" + catchbedMaxUserMassMarkingCommentText + "'," +
                "'" + catchbedArrestChkPass + "'," +
                "'" + catchbedArrestCommentText + "'," +
                "'" + catchbedMattingChkPass + "'," +
                "'" + catchbedMattingCommentText + "'," +
                "'" + catchbedDesignRiskChkPass + "'," +
                "'" + catchbedDesignRiskCommentText + "'," +
                "'" + catchbedIntendedPlayChkPass + "'," +
                "'" + catchbedIntendedPlayRiskCommentText + "'," +
                "'" + catchbedAncillaryFitChkPass + "'," +
                "'" + catchbedAncillaryFitCommentText + "'," +
                "'" + catchbedAncillaryCompliantChkPass + "'," +
                "'" + catchbedAncillaryCompliantCommentText + "'," +
                "'" + catchbedApronChkPass + "'," +
                "'" + catchbedApronCommentText + "'," +
                "'" + catchbedTroughChkPass + "'," +
                "'" + catchbedTroughDepthCommentText + "'," +
                "'" + catchbedFrameworkChkPass + "'," +
                "'" + catchbedFrameworkCommentText + "'," +
                "'" + catchbedGroundingChkPass + "'," +
                "'" + catchbedGroundingCommentText + "'," +
                "'" + catchbedBedHeightValueValue + "'," +
                "'" + catchbedBedHeightChkPass + "'," +
                "'" + catchbedBedHeightCommentText + "'," +
                "'" + catchbedPlatformFallDistanceValueValue + "'," +
                "'" + catchbedPlatformFallDistanceChkPass + "'," +
                "'" + catchbedPlatformFallDistanceCommentText + "'," +
                "'" + catchbedBlowerTubeLengthValueValue + "'," +
                "'" + catchbedBlowerTubeLengthChkPass + "'," +
                "'" + catchbedBlowerTubeLengthCommentText + "'" +

                ")" +
                "RETURNING TagID;"; //I didn't realise sqllite could do this. It saved me a lot of work. I like sqllite a lot. 

            try
            {
                //Doing this so I can get the primary Key (which is the Tag ID)
                object obj = sqlite_cmd.ExecuteScalar(); //Because I am receiving the return value from the query I need to do this instead of sqlite_cmd.ExecuteNonQuery();
                long id = (long)obj;
                //Once the data is inserted in the DB we can retrieve the unique Tag ID (basically the primary key int)
                uniquereportNum.Text = id.ToString();
            }
            catch (Exception e)
            {
                MessageBox.Show(e.ToString(), toolName);
            }

        }


        void saveInspection()
        {
            bool success = false;

            try
            {
                //Create the database
                SQLiteConnection sqlite_conn = CreateConnection();
                CreateTable(sqlite_conn);
                //Insert the data from the inspection (there's no error checking here to make sure they've filled it out, probably should add some?)
                InsertData(sqlite_conn);

                success = true;
                //Important to close this connection - Not sure of the impact of keeping it open and recalling the function (clobbering the database etc)
                sqlite_conn.Close();
            }
            catch (Exception e)
            {
                MessageBox.Show(e.ToString(), toolName);
            }
            if (success == false)
            {
                //Shouldn't really ever get here, but you never know...
                MessageBox.Show("Failed to save inspection to Database.", toolName);
            }
        }

        private void saveBtn_Click(object sender, EventArgs e)
        {
            performNA(); //Don't want to write back values to the database when the unit type isn't applicable.
            saveInspection();
        }

        void performNA()
        {
            if (isBungeeRunChk.Checked == false)
            {
                naBungee();
            }
            if (playZoneIsPlayZoneChk.Checked == false)
            {
                naPlayZone();
            }
            if (isToddlerBallPoolChk.Checked == false)
            {
                naBallPool();
            }
            if (isInflatableGameChk.Checked == false)
            {
                naInflatableGame();
            }
            if (isCatchBedChk.Checked == false)
            {
                naCatchBed();
            }
            if (isSlideChk.Checked == false)
            {
                naSlide();
            }
            if (isUnitEnclosedChk.Checked == false)
            {
                naEnclosed();
            }
        }

        private void createPDFBtn_Click(object sender, EventArgs e)
        {
            createPDFCert();
        }



        Image ConvertStringToImage(string ImgAsString)
        {
            if (ImgAsString.Length > 0)
            {
                Image img = null;

                byte[] imageBytes = Convert.FromBase64String(ImgAsString);

                using (MemoryStream stream = new MemoryStream(imageBytes))
                {
                    img = Image.FromStream(stream);
                }

                return img;
            }
            else
            {
                return null;
            }
        }


        Image compressImage(Image image, double x, double y)
        {
            if (image != null)
            {
                var ratioX = x / image.Width;
                var ratioY = y / image.Height;
                var ratio = Math.Min(ratioX, ratioY);

                var newWidth = (int)(image.Width * ratio);
                var newHeight = (int)(image.Height * ratio);

                var newImage = new Bitmap(newWidth, newHeight);
                Graphics.FromImage(newImage).DrawImage(image, 0, 0, newWidth, newHeight);
                Image bmp = new Bitmap(newImage);

                return bmp;
            }
            else
            {
                return null;
            }
        }


        string ConvertImageToString(Image image)
        {
            if (image != null)
            {
                // First Convert image to byte array.
                byte[] byteArray = new byte[0];
                using (MemoryStream stream = new MemoryStream())
                {
                    image.Save(stream, System.Drawing.Imaging.ImageFormat.Png);
                    stream.Close();

                    byteArray = stream.ToArray();
                }

                // Convert byte[] to Base64 String
                string base64String = Convert.ToBase64String(byteArray);

                return base64String;
            }
            else
            {
                return null;
            }
        }

        /*
        Carefully formatted to make it easier to debug and read. 
        This is the code that loads the records into the datagrid view from the sqlite database
        It clears the records first (obviously you don't wantg them listed multiple times by some idiot clicking the button over and over)
        The function takes the SQL Query as a parameter; Which I thought was a clever way to reuse this, because fuck me it's long and has to be meticulously accurate.
        It performs the query, then it loads each data point into the datagrid.
        */
        void loadRecords(string query)
        {
            clearRecords();

            try
            {
                SQLiteConnection sqlite_conn = CreateConnection();

                string result = "";
                SQLiteDataReader sqlite_datareader;
                SQLiteCommand sqlite_cmd;
                sqlite_cmd = sqlite_conn.CreateCommand();
                sqlite_cmd.CommandText = query;

                sqlite_datareader = sqlite_cmd.ExecuteReader();

                while (sqlite_datareader.Read())
                {
                    records.Rows.Add(
                        sqlite_datareader.GetInt32(0).ToString(), // Primary Key | Tag ID | Unique Report Number
                        ConvertStringToImage(sqlite_datareader.GetString(1)), // Unit Image
                        sqlite_datareader.GetString(2), // Inspection Company
                        sqlite_datareader.GetString(3), // inspection Date
                        sqlite_datareader.GetString(4), // RPII Reg Number
                        sqlite_datareader.GetString(5), // Place Inspected
                        sqlite_datareader.GetString(6), // Unit Description
                        sqlite_datareader.GetString(7), //Unit Manufacturer
                        sqlite_datareader.GetDecimal(8), // Unit Width
                        sqlite_datareader.GetDecimal(9), // Unit Length
                        sqlite_datareader.GetDecimal(10), // Unit Height   
                        sqlite_datareader.GetString(11).ToString(), // Serial
                        sqlite_datareader.GetString(12).ToString(), // Unit Type
                        sqlite_datareader.GetString(13).ToString(), // Unit Owner
                        sqlite_datareader.GetDecimal(14), // Containing Wall Height
                        sqlite_datareader.GetString(15), // Containing Wall Height Comment
                        sqlite_datareader.GetDecimal(16), // platform height
                        sqlite_datareader.GetString(17), // Platform Height Comment
                        sqlite_datareader.GetDecimal(18), // slide barrier height
                        sqlite_datareader.GetString(19), // slide barrier height Comment
                        sqlite_datareader.GetDecimal(20), // remaiing slide wall height height
                        sqlite_datareader.GetString(21), // remaining slide wall Height Comment
                        sqlite_datareader.GetString(22), // perm roof fitted
                        sqlite_datareader.GetString(23), // perm roof comment
                        sqlite_datareader.GetDecimal(24), // user height
                        sqlite_datareader.GetString(25), // user height Comment
                        sqlite_datareader.GetDecimal(26), // play area length
                        sqlite_datareader.GetString(27), // play area length Comment
                        sqlite_datareader.GetDecimal(28), // play area width
                        sqlite_datareader.GetString(29), // play area width Comment
                        sqlite_datareader.GetDecimal(30), // negative adjustment value
                        sqlite_datareader.GetString(31), // negative adjustment Comment
                        sqlite_datareader.GetInt32(32), // Users at 1.0m
                        sqlite_datareader.GetInt32(33), // Users at 1.2m
                        sqlite_datareader.GetInt32(34), // Users at 1.5m
                        sqlite_datareader.GetInt32(35), // Users at 1.8m
                        sqlite_datareader.GetString(36), //Is a slide unit or slide attached?
                        sqlite_datareader.GetDecimal(37), // Slide platform height
                        sqlite_datareader.GetString(38), // slide platform height Comment
                        sqlite_datareader.GetDecimal(39), // slide wall height
                        sqlite_datareader.GetString(40), // slide wall height Comment
                        sqlite_datareader.GetDecimal(41), // slide first metre height
                        sqlite_datareader.GetString(42), // slide first metre height Comment
                        sqlite_datareader.GetDecimal(43), // slide beyond first metre height
                        sqlite_datareader.GetString(44), // slide beyond first metre height Comment
                        sqlite_datareader.GetString(45), // slide perm roof
                        sqlite_datareader.GetString(46), // slide perm roof comment
                        sqlite_datareader.GetString(47), // clamber netting pass
                        sqlite_datareader.GetString(48), // clamber metting comment
                        sqlite_datareader.GetDecimal(49), // run out value
                        sqlite_datareader.GetString(50), // run out pass
                        sqlite_datareader.GetString(51), // run out comment
                        sqlite_datareader.GetString(52), // slip sheet pass
                        sqlite_datareader.GetString(53), // slip sheet comment
                        sqlite_datareader.GetString(54), // seam integrity pass
                        sqlite_datareader.GetString(55), // seam integrity comment
                        sqlite_datareader.GetString(56), // lock stitch pass
                        sqlite_datareader.GetString(57), // lock stitch comment
                        sqlite_datareader.GetInt32(58), // stitch length value
                        sqlite_datareader.GetString(59), // stitch length pass
                        sqlite_datareader.GetString(60), // stitch length comment
                        sqlite_datareader.GetString(61), // Air loss pass
                        sqlite_datareader.GetString(62), // Air loss comment
                        sqlite_datareader.GetString(63), // Straight walls pass
                        sqlite_datareader.GetString(64), // Straight walls comment
                        sqlite_datareader.GetString(65), // Sharp Edges pass
                        sqlite_datareader.GetString(66), // Sharp edges comment
                        sqlite_datareader.GetDecimal(67), // blower tube length
                        sqlite_datareader.GetString(68), // blower tube pass
                        sqlite_datareader.GetString(69), // blower tube comment
                        sqlite_datareader.GetString(70), // unit stable
                        sqlite_datareader.GetString(71), // unit stable comment
                        sqlite_datareader.GetInt32(72), // Evauation Time
                        sqlite_datareader.GetString(73), // Evacuation Time Pass
                        sqlite_datareader.GetString(74), // Evacuation time comment
                        sqlite_datareader.GetDecimal(75), // step size value
                        sqlite_datareader.GetString(76), // step size pass
                        sqlite_datareader.GetString(77), // step size comment
                        sqlite_datareader.GetDecimal(78), // Falloff Height Value
                        sqlite_datareader.GetString(79), // fall off height pass
                        sqlite_datareader.GetString(80), // fall off height comment    
                        sqlite_datareader.GetDecimal(81), // pressure Value
                        sqlite_datareader.GetString(82), // pressure pass
                        sqlite_datareader.GetString(83), // pressure comment
                        sqlite_datareader.GetDecimal(84), // trough depth value
                        sqlite_datareader.GetDecimal(85), // trough width value
                        sqlite_datareader.GetString(86), // trough pass
                        sqlite_datareader.GetString(87), // trough comment
                        sqlite_datareader.GetString(88), // entrapment pass
                        sqlite_datareader.GetString(89), // entrapment comment
                        sqlite_datareader.GetString(90), // marking pass
                        sqlite_datareader.GetString(91), // marking comment
                        sqlite_datareader.GetString(92), // grounding pass
                        sqlite_datareader.GetString(93), // grounding comment
                        sqlite_datareader.GetInt32(94), // number of Low anchors
                        sqlite_datareader.GetInt32(95), // number of High anchors
                        sqlite_datareader.GetString(96), // number of anchors pass
                        sqlite_datareader.GetString(97), // num anchors comment
                        sqlite_datareader.GetString(98), // Anchor Accessories Pass
                        sqlite_datareader.GetString(99), // Anchor Accessories comment
                        sqlite_datareader.GetString(100), // Anchor Degree pass
                        sqlite_datareader.GetString(101), // anchor degree comment
                        sqlite_datareader.GetString(102), // anchor type pass
                        sqlite_datareader.GetString(103), // anchor type comment
                        sqlite_datareader.GetString(104), // pull strength pass
                        sqlite_datareader.GetString(105), // pull strength comment
                        sqlite_datareader.GetString(106), //Is an enclosed Unit?
                        sqlite_datareader.GetInt32(107), // Exit Number
                        sqlite_datareader.GetString(108), // Exit number pass
                        sqlite_datareader.GetString(109), // Exit Number comment
                        sqlite_datareader.GetString(110), // Exit Visible pass
                        sqlite_datareader.GetString(111), // Exit Visible comment
                        sqlite_datareader.GetInt32(112), // rope size
                        sqlite_datareader.GetString(113), // rope size pass
                        sqlite_datareader.GetString(114), // rope size comment
                        sqlite_datareader.GetString(115), // clamber pass
                        sqlite_datareader.GetString(116), // clamber comment
                        sqlite_datareader.GetString(117), // retention netting pass
                        sqlite_datareader.GetString(118), // retention netting comment
                        sqlite_datareader.GetString(119), // zips pass
                        sqlite_datareader.GetString(120), // zips comment
                        sqlite_datareader.GetString(121), // windows pass
                        sqlite_datareader.GetString(122), // windows comment
                        sqlite_datareader.GetString(123), // Artwork pass
                        sqlite_datareader.GetString(124), // Artwork comment
                        sqlite_datareader.GetString(125), // Thread pass
                        sqlite_datareader.GetString(126), // Thread comment
                        sqlite_datareader.GetString(127), // Fabric pass
                        sqlite_datareader.GetString(128), // Fabric comment
                        sqlite_datareader.GetString(129), // Fire Retardent pass
                        sqlite_datareader.GetString(130), // Fire Retardent comment
                        sqlite_datareader.GetString(131), // blower size comment
                        sqlite_datareader.GetString(132), // blower flaps pass
                        sqlite_datareader.GetString(133), // blower flaps comment
                        sqlite_datareader.GetString(134), // blower finger trap pass
                        sqlite_datareader.GetString(135), // blower finger trap comment
                        sqlite_datareader.GetString(136), // PAT Pass pass
                        sqlite_datareader.GetString(137), // PAT Pass comment
                        sqlite_datareader.GetString(138), // blower visual pass
                        sqlite_datareader.GetString(139), // blower visual comment
                        sqlite_datareader.GetString(140), // blower serial
                        sqlite_datareader.GetString(141), // Risk Assessment
                        sqlite_datareader.GetString(142), // passed inspection
                        sqlite_datareader.GetString(143), // Testimony
                        ConvertStringToImage(sqlite_datareader.GetString(144)), // Additional Image 1
                        ConvertStringToImage(sqlite_datareader.GetString(145)), // Additional Image 2
                        ConvertStringToImage(sqlite_datareader.GetString(146)), // Additional Image 3
                        ConvertStringToImage(sqlite_datareader.GetString(147)), // Additioanal Image 4
                        sqlite_datareader.GetString(148), // Operator Manual Present

                        sqlite_datareader.GetString(149), // is Bungee
                        sqlite_datareader.GetString(150), // bungee blower forward distance
                        sqlite_datareader.GetString(151), // bungee blower forward distance comment
                        sqlite_datareader.GetString(152), // bungee markings max mass pass
                        sqlite_datareader.GetString(153), // bungee marking max user mass marking comment
                        sqlite_datareader.GetString(154), // bungee marking minimum user height pass
                        sqlite_datareader.GetString(155), // bungee marking min user height marking comment
                        sqlite_datareader.GetString(156), // bungee pull strength pass
                        sqlite_datareader.GetString(157), // bungee pull strength pass comment
                        sqlite_datareader.GetString(158), // bungee Cord Length Max Pass
                        sqlite_datareader.GetString(159), // bungee Cord Length Max Comment
                        sqlite_datareader.GetString(160), // bungee Cord Diametre Min Pass
                        sqlite_datareader.GetString(161), // bungee Cord Diametre Min Comment
                        sqlite_datareader.GetString(162), // bungee Two Stage Locking Pass
                        sqlite_datareader.GetString(163), // bungee Two Stage Locking Comment
                        sqlite_datareader.GetString(164), // bungee Baton Compliant Pass
                        sqlite_datareader.GetString(165), // bungee Baton Compliant Comment
                        sqlite_datareader.GetString(166), // bungee Lane Width Max Pass
                        sqlite_datareader.GetString(167), // bungee Lane Width Max Comment
                        sqlite_datareader.GetInt32(168), // bungee harness width
                        sqlite_datareader.GetString(169), // bungee harness width pass
                        sqlite_datareader.GetString(170), // bungee harness width comment
                        sqlite_datareader.GetInt32(171), // bungee numb of cords
                        sqlite_datareader.GetDecimal(172), // bungee Rear Wall Thickness Value
                        sqlite_datareader.GetDecimal(173), // bungee Rear Wall Height Value
                        sqlite_datareader.GetString(174), // bungee Rear Wall Pass
                        sqlite_datareader.GetString(175), // bungee Rear Wall Comment
                        sqlite_datareader.GetDecimal(176), // bungee Side Wall Length Value
                        sqlite_datareader.GetDecimal(177), // bungee Side Wall Height Value
                        sqlite_datareader.GetString(178), // bungee Side Wall Pass
                        sqlite_datareader.GetString(179), // bungee Side Wall Comment
                        sqlite_datareader.GetDecimal(180), // bungee Running Wall Width Value
                        sqlite_datareader.GetDecimal(181), // bungee Running Wall Height Value
                        sqlite_datareader.GetString(182), // bungee Running Wall Pass
                        sqlite_datareader.GetString(183), // bungee Running Wall Comment

                        sqlite_datareader.GetString(184), // playZoneIsPlayZoneChk
                        sqlite_datareader.GetString(185), // playZoneAgeMarkingChk
                        sqlite_datareader.GetString(186), // playZoneAgeMarkingComment
                        sqlite_datareader.GetString(187), // playZoneHeightMarkingChk
                        sqlite_datareader.GetString(188), // playZoneHeightMarkingComment
                        sqlite_datareader.GetString(189), // playZoneSightLineChk
                        sqlite_datareader.GetString(190), // playZoneSightLineComment
                        sqlite_datareader.GetString(191), // playZoneAccessChk
                        sqlite_datareader.GetString(192), // playZoneAccessComment
                        sqlite_datareader.GetString(193), // playZoneSuitableMattingChk
                        sqlite_datareader.GetString(194), // playZoneSuitableMattingComment
                        sqlite_datareader.GetString(195), // playZoneTrafficChk
                        sqlite_datareader.GetString(196), // playZoneTrafficFlowComment
                        sqlite_datareader.GetString(197), // playZoneAirJugglerChk
                        sqlite_datareader.GetString(198), // playZoneAirJugglerComment
                        sqlite_datareader.GetString(199), // playZoneBallsChk
                        sqlite_datareader.GetString(200), // playZoneBallsComment
                        sqlite_datareader.GetString(201), // playZoneBallPoolGapsChk
                        sqlite_datareader.GetString(202), // playZoneBallPoolGapsComment
                        sqlite_datareader.GetString(203), // playZoneFittedSheetChk
                        sqlite_datareader.GetString(204), // playZoneFittedSheetComment
                        sqlite_datareader.GetInt32(205), // playZoneBallPoolDepthValue
                        sqlite_datareader.GetString(206), // playZoneBallPoolDepthChk
                        sqlite_datareader.GetString(207), // playZoneBallPoolDepthComment
                        sqlite_datareader.GetInt32(208), // playZoneBallPoolEntryHeightValue
                        sqlite_datareader.GetString(209), // playZoneBallPoolEntryHeightChk
                        sqlite_datareader.GetString(210), // playZoneBallPoolEntryHeightComment
                        sqlite_datareader.GetInt32(211), // playZoneSlideGradValue
                        sqlite_datareader.GetString(212), // playZoneSlideGradChk
                        sqlite_datareader.GetString(213), // playZoneSlideGradComment
                        sqlite_datareader.GetDecimal(214), // playZoneSlideGradValue
                        sqlite_datareader.GetString(215), // playZoneSlideGradChk
                        sqlite_datareader.GetString(216), // playZoneSlideGradComment

                        sqlite_datareader.GetString(217), // isToddlerBallPoolChk
                        sqlite_datareader.GetString(218), // tbpAgeRangeMarkingChk
                        sqlite_datareader.GetString(219), // tbpAgeRangeMarkingComment
                        sqlite_datareader.GetString(220), // tblMaxHeightMarkingsChk
                        sqlite_datareader.GetString(221), // tpbMaxHeightMarkingsComment
                        sqlite_datareader.GetString(222), // tbpSuitableMattingChk
                        sqlite_datareader.GetString(223), // tbpSuitableMattingComment
                        sqlite_datareader.GetString(224), // tbpAirJugglersCompliantChk
                        sqlite_datareader.GetString(225), // tbpAirJugglersCompliantComment
                        sqlite_datareader.GetString(226), // tbpBallsCompliantChk
                        sqlite_datareader.GetString(227), // tbpBallsCompliantComment
                        sqlite_datareader.GetString(228), // tbpGapsChk
                        sqlite_datareader.GetString(229), // tbpGapsComment
                        sqlite_datareader.GetString(230), // tbpFittedBaseChk
                        sqlite_datareader.GetString(231), // tbpFittedBaseComment
                        sqlite_datareader.GetInt32(232), // tbpBallPoolDepthValue
                        sqlite_datareader.GetString(233), // tbpBallPoolDepthChk
                        sqlite_datareader.GetString(234), // tbpBallPoolDepthComment
                        sqlite_datareader.GetInt32(235), // tbpBallPoolEntryValue
                        sqlite_datareader.GetString(236), // tbpBallPoolEntryChk
                        sqlite_datareader.GetString(237), // tbpBallPoolEntryComment

                        sqlite_datareader.GetString(238), // indoor Only

                        sqlite_datareader.GetString(239), // isInflatableGameChk
                        sqlite_datareader.GetString(240), // gameTypeComment
                        sqlite_datareader.GetString(241), // gameMaxUserMassChk
                        sqlite_datareader.GetString(242), // gameMaxUserMassComment
                        sqlite_datareader.GetString(243), // gameAgeRangeMarkingChk
                        sqlite_datareader.GetString(244), // gameAgeRangeMarkingComment
                        sqlite_datareader.GetString(245), // gameConstantAirFlowChk
                        sqlite_datareader.GetString(246), // gameConstantAirFlowComment
                        sqlite_datareader.GetString(247), // gameDesignRiskChk
                        sqlite_datareader.GetString(248), // gameDesignRiskComment
                        sqlite_datareader.GetString(249), // gameIntendedPlayRiskChk
                        sqlite_datareader.GetString(250), // gameIntendedPlayRiskComment
                        sqlite_datareader.GetString(251), // gameAncillaryEquipmentChk
                        sqlite_datareader.GetString(252), // gameAncillaryEquipmentComment
                        sqlite_datareader.GetString(253), // gameAncillaryEquipmentCompliantChk
                        sqlite_datareader.GetString(254), // gameAncillaryEquipmentCompliantComment
                        sqlite_datareader.GetDecimal(255), // gameContainingWallHeightValue
                        sqlite_datareader.GetString(256), // gameContainingWallHeightChk
                        sqlite_datareader.GetString(257), // gameContainingWallHeightComment

                        sqlite_datareader.GetString(258), // isCatchBedChk
                        sqlite_datareader.GetString(259), // catchbedTypeOfUnitComment
                        sqlite_datareader.GetString(260), // catchbedMaxUserMassMarkingChk
                        sqlite_datareader.GetString(261), // catchbedMaxUserMassMarkingComment
                        sqlite_datareader.GetString(262), // catchbedArrestChk
                        sqlite_datareader.GetString(263), // catchbedArrestComment
                        sqlite_datareader.GetString(264), // catchbedMattingChk
                        sqlite_datareader.GetString(265), // catchbedMattingComment
                        sqlite_datareader.GetString(266), // catchbedDesignRiskChk
                        sqlite_datareader.GetString(267), // catchbedDesignRiskComment
                        sqlite_datareader.GetString(268), // catchbedIntendedPlayChk
                        sqlite_datareader.GetString(269), // catchbedIntendedPlayRiskComment
                        sqlite_datareader.GetString(270), // catchbedAncillaryFitChk
                        sqlite_datareader.GetString(271), // catchbedAncillaryFitComment
                        sqlite_datareader.GetString(272), // catchbedAncillaryCompliantChk
                        sqlite_datareader.GetString(273), // catchbedAncillaryCompliantComment
                        sqlite_datareader.GetString(274), // catchbedApronChk
                        sqlite_datareader.GetString(275), // catchbedApronComment
                        sqlite_datareader.GetString(276), // catchbedTroughChk
                        sqlite_datareader.GetString(277), // catchbedTroughDepthComment
                        sqlite_datareader.GetString(278), // catchbedFrameworkChk
                        sqlite_datareader.GetString(279), // catchbedFrameworkComment
                        sqlite_datareader.GetString(280), // catchbedGroundingChk
                        sqlite_datareader.GetString(281), // catchbedGroundingComment
                        sqlite_datareader.GetInt32(282), // catchbedBedHeightValue
                        sqlite_datareader.GetString(283), // catchbedBedHeightChk
                        sqlite_datareader.GetString(284), // catchbedBedHeightComment
                        sqlite_datareader.GetDecimal(285), // catchbedPlatformFallDistanceValue
                        sqlite_datareader.GetString(286), // catchbedPlatformFallDistanceChk
                        sqlite_datareader.GetString(287), // catchbedPlatformFallDistanceComment
                        sqlite_datareader.GetDecimal(288), // catchbedBlowerTubeLengthValue
                        sqlite_datareader.GetString(289), // catchbedBlowerTubeLengthChk
                        sqlite_datareader.GetString(290) // catchbedBlowerTubeLengthComment

                        );
                }
                sqlite_conn.Close();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, toolName);
            }
        }

        /*
        I used to call this quite a bit - Pretty much for the comments of each data point
        It's not ideal, but the comment is drawn on the PDF report and it can't be never ending due to the way the library draws on a single page only and needs defined ends. 
        */
        string truncateText(string text, int maxLength)
        {
            string truncatedComment = text;

            if (truncatedComment.Length > 0 && truncatedComment.Length > maxLength)
            {
                truncatedComment = truncatedComment.Substring(0, maxLength);
            }

            return truncatedComment;
        }


        /*
        This is long as shit and I do not ever want to do it again. 
        There's likely a nice easy way to do this dynamically, rather than statically, but I am not that familiar with pdfSharp
        Maybe I could have created a huge rectangle or something and then used an XTextFormatter to plonk it all in, but either way it was going to be long.
        */
        void createPDFCert()
        {
            if (uniquereportNum.Text.Length > 0)
            {
                try
                {
                    //Document stuff
                    PdfDocument document = new PdfDocument();
                    document.Info.Title = "Inflatable Report - Issued by " + InspectionCompName.Text;
                    document.Info.Creator = InspectionCompName.Text;
                    document.Info.Author = InspectionCompName.Text;

                    //Page stuff
                    PdfPage page1 = document.AddPage();
                    page1.Size = PdfSharp.PageSize.A4;

                    //Set up the graphics
                    GlobalFontSettings.UseWindowsFontsUnderWindows = true;



                    //Set up the fonts (some are pretty small due to how much data is on the page!).
                    XFont h1font = new XFont("Verdana", 14, XFontStyleEx.Bold);
                    XFont h2font = new XFont("Arial", 12, XFontStyleEx.Bold);
                    XFont regularFont = new XFont("Arial", 10, XFontStyleEx.Regular);
                    XFont regularFontBold = new XFont("Arial", 10, XFontStyleEx.Bold);
                    XFont smallFont = new XFont("Arial", 8, XFontStyleEx.Regular);


                    string tempStr = "";


                    //Draw the page 1 stuff. 
                    XGraphics gfx = XGraphics.FromPdfPage(page1);
                    XTextFormatter tf = new XTextFormatter(gfx);
                    //Unit Details Section
                    gfx.DrawString("Unit Details", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                    XRect UnitDetailsRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(28));
                    gfx.DrawRectangle(XBrushes.SeaShell, UnitDetailsRect);

                    tempStr =
                        "Description: " + unitDescriptionText.Text + "\n" +
                        "Manufacturer: " + ManufacturerText.Text + "\n" +
                        "Size (m): Width: " + unitWidthNum.Value.ToString() + " Length: " + unitLengthNum.Value.ToString() + " Height: " + unitHeightNum.Value.ToString() + "\n" +
                        "Serial: " + serialText.Text + "\n" +
                        "Unit Type: " + unitTypeText.Text + "\n" +
                        "Unit Owner: " + unitOwnerText.Text
                        ;
                    tf.DrawString(tempStr, regularFont, XBrushes.Black, UnitDetailsRect, XStringFormats.TopLeft);

                    //User Height Section
                    gfx.DrawString("User Height/Count", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(88));

                    XRect UserHeightRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(89), XUnit.FromMillimeter(200), XUnit.FromMillimeter(100));
                    gfx.DrawRectangle(XBrushes.SeaShell, UserHeightRect);

                    tempStr =
                        "Containing Wall Height: " + containingWallHeightValue.Value.ToString() + "m" + "\n" +
                        "Comment: " + containingWallHeightComment.Text + "\n" +
                        "Tallest Platform Height: " + platformHeightValue.Value.ToString() + "m" + "\n" +
                        "Comment: " + platformHeightComment.Text + "\n" +
                        "Tallest User Height: " + userHeight.Value.ToString() + "m" + "\n" +
                        "Comment: " + userHeightComment.Text + "\n" +
                        "Internal Play Area Length: " + playAreaLengthValue.Value.ToString() + "m" + "\n" +
                        "Comment: " + playAreaLengthComment.Text + "\n" +
                        "Internal Play Area Width: " + playAreaWidthValue.Value.ToString() + "m" + "\n" +
                        "Comment: " + playAreaWidthComment.Text + "\n" +
                        "Negative Adjustment: " + negAdjustmentValue.Value.ToString() + "m" + "\n" +
                        "Comment: " + negAdjustmentComment.Text + "\n" +
                        "Users @ 1.0m: " + usersat1000mm.Value.ToString() + "   Users @ 1.2m: " + usersat1200mm.Value.ToString() + "   Users @ 1.5m: " + usersat1500mm.Value.ToString() + "   Users @ 1.8m: " + usersat1800mm.Value.ToString()
                        ;
                    tf.DrawString(tempStr, regularFont, XBrushes.Black, UserHeightRect, XStringFormats.TopLeft);


                    //Slide Section
                    gfx.DrawString("Slide", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(195));

                    XRect SlideRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(196), XUnit.FromMillimeter(200), XUnit.FromMillimeter(92));
                    gfx.DrawRectangle(XBrushes.SeaShell, SlideRect);

                    tempStr =
                        "Slide Platform Height: " + slidePlatformHeightValue.Value.ToString() + "m" + "\n" +
                        "Comment: " + slidePlatformHeightComment.Text + "\n" +
                        "Containing Wall Height: " + slideWallHeightValue.Value.ToString() + "m" + "\n" +
                        "Comment: " + slideWallHeightComment.Text + "\n" +
                        "First Metre Slide Wall Height: " + slidefirstmetreHeightValue.Value.ToString() + "\n" +
                        "Comment: " + slideFirstMetreHeightComment.Text + "\n" +
                        "Remaining Slide Wall Height: " + beyondfirstmetreHeightValue.Value.ToString() + "m" + "\n" +
                        "Comment: " + beyondfirstmetreHeightComment.Text + "\n" +
                        "Perm Slide Roof Fitted: " + slidePermRoofedCheck.Checked.ToString() + "\n" +
                        "Comment: " + slidePermRoofedComment.Text + "\n" +
                        "Steps/Clamber Netting Pass/Fail: " + clamberNettingPassFail.Checked.ToString() + "\n" +
                        "Comment: " + clamberNettingComment.Text + "\n" +
                        "Slide Run Out: " + runoutValue.Value.ToString() + "m" + "\n" +
                        "Slide Run Out Pass/Fail: " + runOutPassFail.Checked.ToString() + "\n" +
                        "Comment: " + runoutComment.Text + "\n" +
                        "Slip Sheet Integrity Pass/Fail: " + slipsheetPassFail.Checked.ToString() + "\n" +
                        "Comment: " + slipsheetComment.Text
                        ;
                    tf.DrawString(tempStr, regularFont, XBrushes.Black, SlideRect, XStringFormats.TopLeft);

                    gfx.Dispose();

                    //Need a second page here. I kind wish I knew how to draw a dynamic sized rectange and bind the text to that box and have it run over and create a new page if needed.
                    //That would be way better - Esepcially considering comments are sometimes long. Oh well...

                    PdfPage page2 = document.AddPage();
                    page2.Size = PdfSharp.PageSize.A4;
                    XGraphics gfx2 = XGraphics.FromPdfPage(page2);
                    XTextFormatter tf2 = new XTextFormatter(gfx2);
                    //Draw the page 2 stuff. 


                    //Structure Section
                    gfx2.DrawString("Structure", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                    XRect StructureRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(232));
                    gfx2.DrawRectangle(XBrushes.SeaShell, StructureRect);

                    tempStr =
                        "Seam Integrity Pass/Fail: " + seamIntegrityPassFail.Checked.ToString() + "\n" +
                        "Comment: " + seamIntegrityComment.Text + "\n" +
                        "Lock Stitching Pass/Fail: " + lockstitchPassFail.Checked.ToString() + "\n" +
                        "Comment: " + lockStitchComment.Text + "\n" +
                        "Stitch Length: " + stitchLengthValue.Value.ToString() + "mm" + "\n" +
                        "Stitch Length Pass/Fail: " + stitchLengthPassFail.Checked.ToString() + "\n" +
                        "Comment: " + stitchLengthComment.Text + "\n" +
                        "Air Loss Pass/Fail: " + airLossPassFail.Checked.ToString() + "\n" +
                        "Comment: " + airLossComment.Text + "\n" +
                        "Walls and Turrets Vertical Pass/Fail: " + wallStraightPassFail.Checked.ToString() + "\n" +
                        "Comment: " + wallStraightComment.Text + "\n" +
                        "Sharp/Square/Pointed Edges Pass/Fail: " + sharpEdgesPassFail.Checked.ToString() + "\n" +
                        "Comment: " + sharpEdgesComment.Text + "\n" +
                        "Blower Tube Distance: " + tubeDistanceValue.Value.ToString() + "m" + "\n" +
                        "Blower Tube Pass/Fail: " + tubeDistancePassFail.Checked.ToString() + "\n" +
                        "Comment: " + tubeDistanceComment.Text + "\n" +
                        "Unit Stable Pass/Fail: " + stablePassFail.Checked.ToString() + "\n" +
                        "Comment: " + stableComment.Text + "\n" +
                        "Evacuation Time: " + evacTime.Value.ToString() + "\n" +
                        "Evacuation Time Pass/Fail: " + evacTimePassFail.Checked.ToString() + "\n" +
                        "Comment: " + evacTimeComment.Text + "\n" +
                        "Step/Ramp Size: " + stepSizeValue.Value.ToString() + "m" + "\n" +
                        "Step/Ramp Size Pass/Fail: " + stepSizePassFail.Checked.ToString() + "\n" +
                        "Comment: " + stepSizeComment.Text + "\n" +
                        "Critical Fall Off Height: " + falloffHeight.Value.ToString() + "m" + "\n" +
                        "Critical Fall Off Height Pass/Fail: " + falloffHeightPassFail.Checked.ToString() + "\n" +
                        "Comment: " + falloffHeightComment.Text + "\n" +
                        "Critical Fall Off Height: " + falloffHeight.Value.ToString() + "m" + "\n" +
                        "Critical Fall Off Height Pass/Fail: " + falloffHeightPassFail.Checked.ToString() + "\n" +
                        "Comment: " + falloffHeightComment.Text + "\n" +
                        "Unit Pressure: " + pressureValue.Value.ToString() + "Kpa" + "\n" +
                        "Unit Pressure Pass/Fail: " + pressurePassFail.Checked.ToString() + "\n" +
                        "Comment: " + pressureComment.Text + "\n" +
                        "Trough Depth: " + troughDepthValue.Value.ToString() + "mm" + "\n" +
                        "Trough Adjacent Panel Width: " + troughWidthValue.Value.ToString() + "mm" + "\n" +
                        "Trough Pass/Fail: " + troughPassFail.Checked.ToString() + "\n" +
                        "Comment: " + troughComment.Text + "\n" +
                        "Entrapment Pass/Fail: " + entrapPassFail.Checked.ToString() + "\n" +
                        "Comment: " + entrapComment.Text + "\n" +
                        "Markings/ID Pass/Fail: " + markingsPassFail.Checked.ToString() + "\n" +
                        "Comment: " + markingsComment.Text + "\n" +
                        "Grounding Pass/Fail: " + groundingPassFail.Checked.ToString() + "\n" +
                        "Comment: " + groundingComment.Text
                        ;
                    tf2.DrawString(tempStr, regularFont, XBrushes.Black, StructureRect, XStringFormats.TopLeft);

                    gfx2.Dispose();



                    PdfPage page3 = document.AddPage();
                    page3.Size = PdfSharp.PageSize.A4;
                    XGraphics gfx3 = XGraphics.FromPdfPage(page3);
                    XTextFormatter tf3 = new XTextFormatter(gfx3);
                    //Draw the page 3 stuff. 


                    //Anchorage Section
                    gfx3.DrawString("Anchorage", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                    XRect AnchorageRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(75));
                    gfx3.DrawRectangle(XBrushes.SeaShell, AnchorageRect);

                    tempStr =
                        "Total Number of Anchors: " + (numHighAnchors.Value + numLowAnchors.Value).ToString() + "\n" +
                        "Number of Base Anchors: " + numLowAnchors.Value.ToString() + "\n" +
                        "Number of High Anchors: " + numHighAnchors.Value.ToString() + "\n" +
                        "Number of Anchors Pass/Fail: " + numAnchorsPassFail.Checked.ToString() + "\n" +
                        "Comment: " + numAnchorsComment.Text + "\n" +
                        "Anchor Accessories Pass/Fail: " + anchorAccessoriesPassFail.Checked.ToString() + "\n" +
                        "Comment: " + AnchorAccessoriesComment.Text + "\n" +
                        "Anchors Between 30-45° Pass/Fail: " + anchorDegreePassFail.Checked.ToString() + "\n" +
                        "Comment: " + anchorDegreesComment.Text + "\n" +
                        "Anchors Perm Closed Pass/Fail: " + anchorTypePassFail.Checked.ToString() + "\n" +
                        "Comment: " + anchorTypeComment.Text + "\n" +
                        "Pull Strength Pass/Fail: " + pullStrengthPassFail.Checked.ToString() + "\n" +
                        "Comment: " + pullStrengthComment.Text
                        ;
                    tf3.DrawString(tempStr, regularFont, XBrushes.Black, AnchorageRect, XStringFormats.TopLeft);


                    //Totally Enclosed Section
                    gfx3.DrawString("Totally Enclosed", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(137));

                    XRect EnclosedRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(138), XUnit.FromMillimeter(200), XUnit.FromMillimeter(32));
                    gfx3.DrawRectangle(XBrushes.SeaShell, EnclosedRect);

                    tempStr =
                        "Number of Exits: " + exitNumberValue.Value.ToString() + "\n" +
                        "Number of Exits Pass/Fail: " + exitNumberPassFail.Checked.ToString() + "\n" +
                        "Comment: " + exitNumberComment.Text + "\n" +
                        "Number of Exits Pass/Fail: " + exitsignVisiblePassFail.Checked.ToString() + "\n" +
                        "Comment: " + exitSignVisibleComment.Text
                        ;
                    tf3.DrawString(tempStr, regularFont, XBrushes.Black, EnclosedRect, XStringFormats.TopLeft);


                    //Materials Section
                    gfx3.DrawString("Materials", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(177));

                    XRect MaterialsRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(178), XUnit.FromMillimeter(200), XUnit.FromMillimeter(110));
                    gfx3.DrawRectangle(XBrushes.SeaShell, MaterialsRect);

                    tempStr =
                        "Ropes: " + ropesizeValue.Value.ToString() + "mm" + "\n" +
                        "Ropes Pass/Fail: " + ropeSizePassFail.Checked.ToString() + "\n" +
                        "Comment: " + ropeSizeComment.Text + "\n" +
                        "Clamber Netting Pass/Fail: " + clamberPassFail.Checked.ToString() + "\n" +
                        "Comment: " + clamberComment.Text + "\n" +
                        "Retention Netting Pass/Fail: " + retentionNettingPassFail.Checked.ToString() + "\n" +
                        "Comment: " + retentionNettingComment.Text + "\n" +
                        "Zips Pass/Fail: " + zipsPassFail.Checked.ToString() + "\n" +
                        "Comment: " + zipsComment.Text + "\n" +
                        "Windows Pass/Fail: " + windowsPassFail.Checked.ToString() + "\n" +
                        "Comment: " + windowsComment.Text + "\n" +
                        "Artwork Pass/Fail: " + artworkPassFail.Checked.ToString() + "\n" +
                        "Comment: " + artworkComment.Text + "\n" +
                        "Thread Pass/Fail: " + threadPassFail.Checked.ToString() + "\n" +
                        "Comment: " + threadComment.Text + "\n" +
                        "Fabric Strength Pass/Fail: " + fabricPassFail.Checked.ToString() + "\n" +
                        "Comment: " + fabricComment.Text + "\n" +
                        "Fire Retardent Pass/Fail: " + fireRetardentPassFail.Checked.ToString() + "\n" +
                        "Comment: " + fireRetardentComment.Text
                        ;
                    tf3.DrawString(tempStr, regularFont, XBrushes.Black, MaterialsRect, XStringFormats.TopLeft);
                    gfx3.Dispose();


                    if (isBungeeRunChk.Checked == true) //If the bungee section is relevant then make a page for it.
                    {
                        PdfPage pageBungee = document.AddPage();
                        pageBungee.Size = PdfSharp.PageSize.A4;
                        XGraphics gfxbungee = XGraphics.FromPdfPage(pageBungee);
                        XTextFormatter tfbungee = new XTextFormatter(gfxbungee);
                        //Draw the bungee page stuff. 


                        //Bungee Section
                        gfxbungee.DrawString("Bungee Run", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                        XRect BungeeRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(232));
                        gfxbungee.DrawRectangle(XBrushes.SeaShell, BungeeRect);

                        tempStr =
                            "Blower is no more than 1.5m foward of the rear wall: " + bungeeBlowerDistanceChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeBlowerDistanceComment.Text + "\n" +
                            "Marking present to indicate max user mass of 120kg: " + bungeeMaxMassChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeUserMaxMassComment.Text + "\n" +
                            "Marking present to indicate Minimum user height of 1.2m: " + bungeeMinHeightChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeMinHeightComment.Text + "\n" +
                            "Harness pull strength test to 1200n: " + bungeePullTestChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeHarnessPullTestComment.Text + "\n" +
                            "All cords are a maximum length of 3.3m: " + bungeeCordLengthChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeCordLengthComment.Text + "\n" +
                            "All cord diametres are a minimum of 12.5 millimetres in diametre: " + bungeeCordDiametreChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeCordDiametreComment.Text + "\n" +
                            "Two-Stage locking system present: " + bungeeTwoStageChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeTwoStageComment.Text + "\n" +
                            "Baton is compliant: " + bungeeBatonCompliantChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeBatonCompliantComment.Text + "\n" +
                            "Each lane is a max of 900mm wide: " + bungeeLaneWidthChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeLaneWidthComment.Text + "\n" +
                            "Harness width in millimetres: " + bungeeHarnessWidth.Value.ToString() + "\n" +
                            "Harness width meets requirements: " + bungeeHarnessWidthPassChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeHarnessWidthComment.Text + "\n" +
                            "Number of cords: " + bungeeHarnessWidth.Value.ToString() + "\n" +
                            "Rear wall thickness in metres: " + bungeeRearWallWidthNum.Value.ToString() + "\n" +
                            "Rear wall height in metres: " + bungeeRearWallHeight.Value.ToString() + "\n" +
                            "Rear wall dimensions meets requirements: " + bungeeRearWallChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeRearWallComment.Text + "\n" +
                            "Side wall (starting position) length in metres: " + bungeeStartingPosWallsLengthNum.Value.ToString() + "\n" +
                            "Side wall (starting position) height in metres: " + bungeeStartingPosWallsHeightNum.Value.ToString() + "\n" +
                            "Side wall (starting position) dimensions meets requirements: " + bungeeStartingPosWallChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeStartingPosWallsComment.Text + "\n" +
                            "Running walls thickness in metres: " + bungeeRunningWallWidthNum.Value.ToString() + "\n" +
                            "Running walls height in metres: " + bungeeRunningWallHeightNum.Value.ToString() + "\n" +
                            "Running walls (starting position) dimensions meets requirements: " + bungeeRunningWallChk.Checked.ToString() + "\n" +
                            "Comment: " + bungeeRunningWallComment.Text + "\n"
                            ;
                        tfbungee.DrawString(tempStr, regularFont, XBrushes.Black, BungeeRect, XStringFormats.TopLeft);


                        gfxbungee.Dispose();
                    }


                    if (playZoneIsPlayZoneChk.Checked == true) //If the playzone/toddler zone section is relevant then make a page for it.
                    {
                        PdfPage pagePlayZone = document.AddPage();
                        pagePlayZone.Size = PdfSharp.PageSize.A4;
                        XGraphics gfxplayzone = XGraphics.FromPdfPage(pagePlayZone);
                        XTextFormatter tfplayzone = new XTextFormatter(gfxplayzone);

                        //toddler/play zone Section
                        gfxplayzone.DrawString("Toddler Zone/Play Zone", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                        XRect PlayZoneRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(232));
                        gfxplayzone.DrawRectangle(XBrushes.SeaShell, PlayZoneRect);

                        tempStr =
                            "Marking present to indicate age range: " + playZoneAgeMarkingChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneAgeMarkingComment.Text + "\n" +
                            "Marking present to indicate max. user height: " + playZoneHeightMarkingChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneHeightMarkingComment.Text + "\n" +
                            "Sight lines clear to observe playing areas: " + playZoneSightLineChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneSightLineComment.Text + "\n" +
                            "Access, Egress and Connections safe: " + playZoneAccessChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneAccessComment.Text + "\n" +
                            "Suitable Matting: " + playZoneSuitableMattingChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneSuitableMattingComment.Text + "\n" +
                            "Traffic flow design safe: " + playZoneTrafficChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneTrafficFlowComment.Text + "\n" +
                            "Air Jugglers Compliant: " + playZoneAirJugglerChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneAirJugglerComment.Text + "\n" +
                            "Balls Compliant: " + playZoneBallsChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneBallsComment.Text + "\n" +
                            "No gaps in Ball Pool: " + playZoneBallPoolGapsChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneBallPoolGapsComment.Text + "\n" +
                            "Fitted base sheet: " + playZoneFittedSheetChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneFittedSheetComment.Text + "\n" +
                            "Ball Pool Depth (mm): " + playZoneBallPoolDepthValue.Value.ToString() + "\n" +
                            "Ball Pool Depth Pass: " + playZoneBallPoolDepthChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneBallPoolDepthComment.Text + "\n" +
                            "Ball Pool Entry Height (mm): " + playZoneBallPoolEntryHeightValue.Value.ToString() + "\n" +
                            "Ball Pool Entry Height Pass: " + playZoneBallPoolEntryHeightChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneBallPoolEntryHeightComment.Text + "\n" +
                            "Platform Incline Gradient (deg): " + playZoneSlideGradValue.Value.ToString() + "\n" +
                            "Platform Incline Gradient Pass: " + playZoneSlideGradChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneSlideGradComment.Text + "\n" +
                            "Slide Platform Height (m): " + playZoneSlidePlatHeightValue.Value.ToString() + "\n" +
                            "Slide Platform Height Pass: " + playZoneSlidePlatHeightChk.Checked.ToString() + "\n" +
                            "Comment: " + playZoneSlidePlatHeightComment.Text
                            ;
                        tfplayzone.DrawString(tempStr, regularFont, XBrushes.Black, PlayZoneRect, XStringFormats.TopLeft);
                        gfxplayzone.Dispose();
                    }

                    if (isToddlerBallPoolChk.Checked == true) //If the toddler ball pool section is relevant then make a page for it.
                    {
                        PdfPage pageBallPool = document.AddPage();
                        pageBallPool.Size = PdfSharp.PageSize.A4;
                        XGraphics gfxballpool = XGraphics.FromPdfPage(pageBallPool);
                        XTextFormatter tfballpool = new XTextFormatter(gfxballpool);

                        //Ball Pool Section
                        gfxballpool.DrawString("Inflatable Ball Pool", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                        XRect BallPoolRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(232));
                        gfxballpool.DrawRectangle(XBrushes.SeaShell, BallPoolRect);

                        tempStr =
                            "Marking present to indicate age range: " + tbpAgeRangeMarkingChk.Checked.ToString() + "\n" +
                            "Comment: " + tbpAgeRangeMarkingComment.Text + "\n" +
                            "Marking present to indicate max. user height: " + tblMaxHeightMarkingsChk.Checked.ToString() + "\n" +
                            "Comment: " + tpbMaxHeightMarkingsComment.Text + "\n" +
                            "Suitable Matting: " + tbpSuitableMattingChk.Checked.ToString() + "\n" +
                            "Comment: " + tbpSuitableMattingComment.Text + "\n" +
                            "Air Jugglers Compliant: " + tbpAirJugglersCompliantChk.Checked.ToString() + "\n" +
                            "Comment: " + tbpAirJugglersCompliantComment.Text + "\n" +
                            "Balls Compliant: " + tbpBallsCompliantChk.Checked.ToString() + "\n" +
                            "Comment: " + tbpBallsCompliantComment.Text + "\n" +
                            "No gaps in Ball Pool: " + tbpGapsChk.Checked.ToString() + "\n" +
                            "Comment: " + tbpGapsComment.Text + "\n" +
                            "Fitted base sheet: " + tbpFittedBaseChk.Checked.ToString() + "\n" +
                            "Comment: " + tbpFittedBaseComment.Text + "\n" +
                            "Ball Pool Depth (mm): " + tbpBallPoolDepthValue.Value.ToString() + "\n" +
                            "Ball Pool Depth Pass: " + tbpBallPoolDepthChk.Checked.ToString() + "\n" +
                            "Comment: " + tbpBallPoolDepthComment.Text + "\n" +
                            "Ball Pool Entry Height (mm): " + tbpBallPoolEntryValue.Value.ToString() + "\n" +
                            "Ball Pool Entry Height Pass: " + tbpBallPoolEntryChk.Checked.ToString() + "\n" +
                            "Comment: " + tbpBallPoolEntryComment.Text + "\n"
                            ;
                        tfballpool.DrawString(tempStr, regularFont, XBrushes.Black, BallPoolRect, XStringFormats.TopLeft);
                        gfxballpool.Dispose();
                    }

                    if (isInflatableGameChk.Checked == true) //If the inflatable game section is relevant then make a page for it.
                    {
                        PdfPage pageGame = document.AddPage();
                        pageGame.Size = PdfSharp.PageSize.A4;
                        XGraphics gfxgame = XGraphics.FromPdfPage(pageGame);
                        XTextFormatter tfgame = new XTextFormatter(gfxgame);

                        //Inflatable Game Section
                        gfxgame.DrawString("Inflatable Game", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                        XRect GameRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(232));
                        gfxgame.DrawRectangle(XBrushes.SeaShell, GameRect);

                        tempStr =
                            "Type of Inflatable Game (description): " + gameTypeComment.Text.ToString() + "\n" +
                            "Marking present to indicate max user mass: " + gameMaxUserMassChk.Checked.ToString() + "\n" +
                            "Comment: " + gameMaxUserMassComment.Text + "\n" +
                            "Marking present to indicate Age Range: " + gameAgeRangeMarkingChk.Checked.ToString() + "\n" +
                            "Comment: " + gameAgeRangeMarkingComment.Text + "\n" +
                            "Inflatable is constant air-flow unit: " + gameConstantAirFlowChk.Checked.ToString() + "\n" +
                            "Comment: " + gameConstantAirFlowComment.Text + "\n" +
                            "Design and Construction Minimises Risk: " + gameDesignRiskChk.Checked.ToString() + "\n" +
                            "Comment: " + gameDesignRiskComment.Text + "\n" +
                            "Intended Play Minimises Risk: " + gameIntendedPlayRiskChk.Checked.ToString() + "\n" +
                            "Comment: " + gameIntendedPlayRiskComment.Text + "\n" +
                            "Ancillary Equipment Fit For Purpose: " + gameAncillaryEquipmentChk.Checked.ToString() + "\n" +
                            "Comment: " + gameAncillaryEquipmentComment.Text + "\n" +
                            "Ancillary Equipment Compliant: " + gameAncillaryEquipmentCompliantChk.Checked.ToString() + "\n" +
                            "Comment: " + gameAncillaryEquipmentCompliantComment.Text + "\n" +
                            "Containing Wall Height (m): " + gameContainingWallHeightValue.Value.ToString() + "\n" +
                            "Containing Wall Height Pass: " + gameContainingWallHeightChk.Checked.ToString() + "\n" +
                            "Comment: " + gameContainingWallHeightComment.Text + "\n"
                            ;
                        tfgame.DrawString(tempStr, regularFont, XBrushes.Black, GameRect, XStringFormats.TopLeft);
                        gfxgame.Dispose();
                    }

                    if (isCatchBedChk.Checked == true) //If the catch-bed section is relevant then make a page for it.
                    {
                        PdfPage pageCB = document.AddPage();
                        pageCB.Size = PdfSharp.PageSize.A4;
                        XGraphics gfxcb = XGraphics.FromPdfPage(pageCB);
                        XTextFormatter tfcb = new XTextFormatter(gfxcb);

                        //Catch-Bed Section
                        gfxcb.DrawString("Catch Bed", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                        XRect CBRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(232));
                        gfxcb.DrawRectangle(XBrushes.SeaShell, CBRect);

                        tempStr =
                            "Type of Catch Bed: " + isCatchBedChk.Text.ToString() + "\n" +
                            "Marking present to indicate max user mass: " + catchbedMaxUserMassMarkingChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedMaxUserMassMarkingComment.Text + "\n" +
                            "Bed suitable to arrest users when falling: " + catchbedArrestChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedArrestComment.Text + "\n" +
                            "Suitable Matting: " + catchbedMattingChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedMattingComment.Text + "\n" +
                            "Design and Construction Minimises Risk: " + catchbedDesignRiskChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedDesignRiskComment.Text + "\n" +
                            "Intended Play Minimises Risk: " + catchbedIntendedPlayChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedIntendedPlayRiskComment.Text + "\n" +
                            "Ancillary Equipment Fit For Purpose: " + catchbedAncillaryFitChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedAncillaryFitComment.Text + "\n" +
                            "Ancillary Equipment Compliant: " + catchbedAncillaryCompliantChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedAncillaryCompliantComment.Text + "\n" +
                            "Suitable Apron and padding: " + catchbedApronChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedApronComment.Text + "\n" +
                            "Trough depth suitable: " + catchbedTroughChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedTroughDepthComment.Text + "\n" +
                            "Framework Secure: " + catchbedFrameworkChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedFrameworkComment.Text + "\n" +
                            "120kg Grounding Test: " + catchbedGroundingChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedGroundingComment.Text + "\n" +
                            "Bed Height (mm): " + catchbedBedHeightValue.Value.ToString() + "\n" +
                            "Bed Height Sufficient: " + catchbedBedHeightChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedBedHeightComment.Text + "\n" +
                            "Distance from edge of platform to inside containing wall (m): " + catchbedPlatformFallDistanceValue.Value.ToString() + "\n" +
                            "Distance Sufficient: " + catchbedPlatformFallDistanceChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedPlatformFallDistanceComment.Text + "\n" +
                            "Blower tube length (metres): " + catchbedBlowerTubeLengthValue.Value.ToString() + "\n" +
                            "Distance Sufficient: " + catchbedBlowerTubeLengthChk.Checked.ToString() + "\n" +
                            "Comment: " + catchbedBlowerTubeLengthComment.Text + "\n"
                            ;
                        tfcb.DrawString(tempStr, regularFont, XBrushes.Black, CBRect, XStringFormats.TopLeft);
                        gfxcb.Dispose();
                    }


                    PdfPage page4 = document.AddPage();
                    page4.Size = PdfSharp.PageSize.A4;
                    XGraphics gfx4 = XGraphics.FromPdfPage(page4);
                    XTextFormatter tf4 = new XTextFormatter(gfx4);
                    //Draw the page 3 stuff. 


                    //Fan/Blower Section
                    gfx4.DrawString("Fan/Blower", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(54));

                    XRect FanRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(55), XUnit.FromMillimeter(200), XUnit.FromMillimeter(50));
                    gfx4.DrawRectangle(XBrushes.SeaShell, FanRect);

                    tempStr =
                        "Blower Size: " + blowerSizeComment.Text + "\n" +
                        "Return Flap Pass/Fail: " + blowerFlapPassFail.Checked.ToString() + "\n" +
                        "Finger Probe Test Pass/Fail: " + blowerFingerPassFail.Checked.ToString() + "\n" +
                        "Comment: " + blowerFingerComment.Text + "\n" +
                        "PAT Test Pass/Fail: " + patPassFail.Checked.ToString() + "\n" +
                        "Comment: " + patComment.Text + "\n" +
                        "Visual Inspection Pass/Fail: " + blowerVisualPassFail.Checked.ToString() + "\n" +
                        "Comment: " + blowerVisualComment.Text + "\n" +
                        "Blower Serial: " + blowerSerial.Text
                        ;
                    tf4.DrawString(tempStr, regularFont, XBrushes.Black, FanRect, XStringFormats.TopLeft);


                    //Risk Assessment Section
                    gfx4.DrawString("Risk Assessment", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(113));

                    XRect RARect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(114), XUnit.FromMillimeter(200), XUnit.FromMillimeter(80));
                    gfx4.DrawRectangle(XBrushes.LavenderBlush, RARect);

                    tempStr =
                        riskAssessmentNotes.Text;
                    ;
                    tf4.DrawString(tempStr, regularFont, XBrushes.Red, RARect, XStringFormats.TopLeft);


                    //Operator Manual Section
                    XRect opManualRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(196), XUnit.FromMillimeter(200), XUnit.FromMillimeter(8));
                    gfx4.DrawRectangle(XBrushes.LavenderBlush, opManualRect);

                    if (operatorManualChk.Checked == false)
                    {
                        tempStr =
                            "Advisory: Operations Manual not presented at time of inspection. Controller advised to obtain or develop the operations manual to ensure that they can demonstrate their duty, safe use and set-up.";
                        tf4.DrawString(tempStr, regularFont, XBrushes.Black, opManualRect, XStringFormats.TopLeft);
                    }
                    else
                    {
                        tempStr =
                            "Operations Manual presented at time of inspection and in good order."
                            ;
                        tf4.DrawString(tempStr, regularFont, XBrushes.Black, opManualRect, XStringFormats.TopLeft);
                    }

                    //Indoor use Only
                    XRect indoorRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(206), XUnit.FromMillimeter(200), XUnit.FromMillimeter(4));
                    gfx4.DrawRectangle(XBrushes.LavenderBlush, indoorRect);

                    if (indoorOnlyChk.Checked == true)
                    {
                        tempStr =
                            "Inflatable device inspected for indoor use only - Not to be used outdoors.";
                        tf4.DrawString(tempStr, regularFontBold, XBrushes.Black, indoorRect, XStringFormats.TopLeft);
                    }
                    else
                    {
                        tempStr =
                            "Inflatable device inspected for outdoor and indoor use."
                            ;
                        tf4.DrawString(tempStr, regularFont, XBrushes.Black, indoorRect, XStringFormats.TopLeft);
                    }

                    //Testimony Section
                    XRect TestimonyRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(212), XUnit.FromMillimeter(200), XUnit.FromMillimeter(8));
                    gfx4.DrawRectangle(XBrushes.SeaShell, TestimonyRect);

                    if (passedRadio.Checked == false)
                    {
                        tempStr =
                            "Testimony: The equipment identified above was inspected and FAILED to meet the safety criteria required using all relevant sections of the European Standard EN 14960:2019 on the above date.";
                        tf4.DrawString(tempStr, regularFont, XBrushes.Black, TestimonyRect, XStringFormats.TopLeft);
                    }
                    else
                    {
                        tempStr =
                            "Testimony: " + testimony.Text
                            ;
                        tf4.DrawString(tempStr, regularFont, XBrushes.Black, TestimonyRect, XStringFormats.TopLeft);
                    }

                    //Photo Section
                    gfx4.DrawString("Inflatable Photo", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(226));

                    //If there is a photo, might as well add it to the report...
                    if (unitPic.Image != null)
                    {
                        MemoryStream strm = new MemoryStream();
                        Image img = compressImage(unitPic.Image, (double)240, (double)195);
                        img.Save(strm, System.Drawing.Imaging.ImageFormat.Png);
                        XImage xfoto = XImage.FromStream(strm);
                        gfx4.DrawImage(xfoto, XUnit.FromMillimeter(5), XUnit.FromMillimeter(227), img.Width, img.Height);
                    }

                    gfx4.Dispose();


                    //Additional Photos
                    //Only create the page if additional photos exist.
                    if (AdditionalPic1.Image != null || AdditionalPic2.Image != null || AdditionalPic3.Image != null || AdditionalPic4.Image != null)
                    {
                        PdfPage page5 = document.AddPage();
                        page5.Size = PdfSharp.PageSize.A4;
                        XGraphics gfx5 = XGraphics.FromPdfPage(page5);
                        //Draw the page 5 stuff. 

                        gfx5.DrawString("Additional Photo 1", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(70));
                        if (AdditionalPic1.Image != null)
                        {
                            MemoryStream strm = new MemoryStream();
                            Image img = compressImage(AdditionalPic1.Image, (double)240, (double)195);
                            img.Save(strm, System.Drawing.Imaging.ImageFormat.Png);
                            XImage xfoto = XImage.FromStream(strm);
                            gfx5.DrawImage(xfoto, XUnit.FromMillimeter(5), XUnit.FromMillimeter(71), img.Width, img.Height);
                        }

                        gfx5.DrawString("Additional Photo 2", h2font, XBrushes.Black, XUnit.FromMillimeter(117), XUnit.FromMillimeter(70));
                        if (AdditionalPic2.Image != null)
                        {
                            MemoryStream strm = new MemoryStream();
                            Image img = compressImage(AdditionalPic2.Image, (double)240, (double)195);
                            img.Save(strm, System.Drawing.Imaging.ImageFormat.Png);
                            XImage xfoto = XImage.FromStream(strm);
                            gfx5.DrawImage(xfoto, XUnit.FromMillimeter(117), XUnit.FromMillimeter(71), img.Width, img.Height);
                        }

                        gfx5.DrawString("Additional Photo 3", h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(150));
                        if (AdditionalPic3.Image != null)
                        {
                            MemoryStream strm = new MemoryStream();
                            Image img = compressImage(AdditionalPic3.Image, (double)240, (double)195);
                            img.Save(strm, System.Drawing.Imaging.ImageFormat.Png);
                            XImage xfoto = XImage.FromStream(strm);
                            gfx5.DrawImage(xfoto, XUnit.FromMillimeter(5), XUnit.FromMillimeter(151), img.Width, img.Height);
                        }


                        gfx5.DrawString("Additional Photo 4", h2font, XBrushes.Black, XUnit.FromMillimeter(117), XUnit.FromMillimeter(150));
                        if (AdditionalPic4.Image != null)
                        {
                            MemoryStream strm = new MemoryStream();
                            Image img = compressImage(AdditionalPic4.Image, (double)240, (double)195);
                            img.Save(strm, System.Drawing.Imaging.ImageFormat.Png);
                            XImage xfoto = XImage.FromStream(strm);
                            gfx5.DrawImage(xfoto, XUnit.FromMillimeter(117), XUnit.FromMillimeter(151), img.Width, img.Height);
                        }

                        gfx5.Dispose();
                    }

                    //This drawing goes on every page - So it loops. Do this at the end so all pages are added already.

                    for (int i = 0; i < document.Pages.Count; ++i)
                    {
                        PdfPage page = document.Pages[i];

                        using (XGraphics grfx = XGraphics.FromPdfPage(page))
                        {
                            XTextFormatter headertf = new XTextFormatter(grfx);
                            string temp = "";

                            //Draw the Inspectors logo
                            if (inspectorsLogo.Image != null)
                            {
                                MemoryStream strm = new MemoryStream();
                                Image img = compressImage(inspectorsLogo.Image, (double)175, (double)135);
                                img.Save(strm, System.Drawing.Imaging.ImageFormat.Png);
                                XImage xfoto = XImage.FromStream(strm);
                                grfx.DrawImage(xfoto, XUnit.FromMillimeter(145), XUnit.FromMillimeter(2), img.Width, img.Height);
                            }

                            //Draw the header stuff
                            grfx.DrawString("RPII Inspector Issued Report", h1font, XBrushes.Blue, XUnit.FromMillimeter(5), XUnit.FromMillimeter(7));
                            grfx.DrawString("Issued by: " + InspectionCompName.Text, h2font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(12));
                            grfx.DrawString("Date Issued: " + datePicker.Value.ToShortDateString(), h1font, XBrushes.Green, XUnit.FromMillimeter(5), XUnit.FromMillimeter(17));
                            grfx.DrawString("RPII Reg Number: " + rpiiReg.Text, h1font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(27));
                            /* Place of inspection might go multi-line, so put it in this rect.*/
                            XRect PlaceOfInspectionRect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(28), XUnit.FromMillimeter(130), XUnit.FromMillimeter(10));
                            //grfx.DrawRectangle(XBrushes.Linen, PlaceOfInspectionRect);
                            temp = "Place of Inspection: " + inspectionLocation.Text;
                            headertf.DrawString(temp, regularFont, XBrushes.Black, PlaceOfInspectionRect, XStringFormats.TopLeft);
                            /**********************************************************************************************************************************************************/
                            grfx.DrawString("Unique Report Number: " + uniquereportNum.Text, regularFontBold, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(39));

                            grfx.DrawString("Result: ", h1font, XBrushes.Black, XUnit.FromMillimeter(5), XUnit.FromMillimeter(44));
                            //Dynamic/decision based logic to print "passed" in Green or "failed" in red.
                            if (passedRadio.Checked == false)
                            {
                                grfx.DrawString("Failed Inspection", h1font, XBrushes.Red, XUnit.FromMillimeter(26), XUnit.FromMillimeter(44));
                                grfx.DrawString("Date Expires: Failed Inspection", h1font, XBrushes.Red, XUnit.FromMillimeter(5), XUnit.FromMillimeter(22));
                            }
                            else
                            {
                                grfx.DrawString("Passed Inspection", h1font, XBrushes.Green, XUnit.FromMillimeter(26), XUnit.FromMillimeter(44));
                                grfx.DrawString("Date Expires: " + datePicker.Value.AddYears(1).ToShortDateString(), h1font, XBrushes.Red, XUnit.FromMillimeter(5), XUnit.FromMillimeter(22));
                            }

                            /* Spencer's comment about making the software.*/
                            XRect rect = new XRect(XUnit.FromMillimeter(5), XUnit.FromMillimeter(292), XUnit.FromMillimeter(90), XUnit.FromMillimeter(4));
                            grfx.DrawRectangle(XBrushes.LavenderBlush, rect);
                            grfx.DrawString("The software used to generate this report was made by Spencer Elliott.", smallFont, XBrushes.Black, rect, XStringFormats.TopLeft);
                            /**********************************************************************************************************************************************************/

                            /* Page Numbering */
                            XRect pagination = new XRect(XUnit.FromMillimeter(184), XUnit.FromMillimeter(291), XUnit.FromMillimeter(20), XUnit.FromMillimeter(4));
                            //grfx.DrawRectangle(XBrushes.LavenderBlush, pagination); //Pagination doesn't really need colouring. 
                            grfx.DrawString("Page " + (i + 1).ToString() + " of " + document.Pages.Count.ToString(), regularFontBold, XBrushes.Black, pagination, XStringFormats.TopLeft);
                            /**********************************************************************************************************************************************************/
                        }
                    }


                    string path = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "RPII Reports ", DateTime.Now.ToString("yyyy-MM-dd"));
                    bool exists = System.IO.Directory.Exists(path);
                    if (!exists)
                    {
                        System.IO.Directory.CreateDirectory(path);
                    }
                    string filename = DateTime.Now.ToString("yyyy-MM-dd") + " - Inspection Report - " + unitDescriptionText.Text + " " + uniquereportNum.Text + ".pdf";

                    document.Save(path + "\\" + filename);

                    //Remove the Unique report number - Will force the user to re-save the report to the database before creating another PDF.
                    uniquereportNum.Text = "";
                }


                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message, toolName);
                }
            }
            else
            {
                MessageBox.Show("Save inspection to database to generate unique report number first.", toolName);
            }
        }

        void newReport()
        {
            /* This has been carefully set-up to only clear out the data from the current inspection.
             * The assumption here is that you'll be on-site at a customer's and their details will stay the same.
             * You don't want to keep typing their address in, or their company name for example... */


            inspectionTabControl.TabPages.Remove(BungeeTab);
            inspectionTabControl.TabPages.Remove(Bungee2Tab);
            inspectionTabControl.TabPages.Remove(PlayZoneTab);
            inspectionTabControl.TabPages.Remove(PlayZoneTabCont);
            inspectionTabControl.TabPages.Remove(BallPoolTab);
            inspectionTabControl.TabPages.Remove(inflatableGameTab);
            inspectionTabControl.TabPages.Remove(SlideTab);
            inspectionTabControl.TabPages.Remove(EnclosedTab);
            inspectionTabControl.TabPages.Remove(catchbedTab);
            inspectionTabControl.TabPages.Remove(catchbedContTab);

            //Unit Details
            uniquereportNum.Text = "";
            unitDescriptionText.Text = "";
            ManufacturerText.Text = "";
            serialText.Text = "";
            unitTypeText.Text = "";
            unitPic.Image = null;
            unitWidthNum.Value = (decimal)3.00;
            unitLengthNum.Value = (decimal)4.00;
            unitHeightNum.Value = (decimal)3.00;
            passedRadio.Checked = true;

            //Bungee
            isBungeeRunChk.Checked = false;
            bungeeBlowerDistanceChk.Checked = false;
            bungeeMaxMassChk.Checked = false;
            bungeeMinHeightChk.Checked = false;
            bungeePullTestChk.Checked = false;
            bungeeCordLengthChk.Checked = false;
            bungeeCordDiametreChk.Checked = false;
            bungeeTwoStageChk.Checked = false;
            bungeeBatonCompliantChk.Checked = false;
            bungeeLaneWidthChk.Checked = false;
            bungeeHarnessWidth.Value = 200;
            bungeeHarnessWidthPassChk.Checked = false;
            bungeeCordAmount.Value = 2;
            bungeeRearWallChk.Checked = false;
            bungeeRearWallWidthNum.Value = (decimal)0.6;
            bungeeRearWallHeight.Value = (decimal)1.8;
            bungeeStartingPosWallChk.Checked = false;
            bungeeStartingPosWallsLengthNum.Value = (decimal)1.5;
            bungeeStartingPosWallsHeightNum.Value = (decimal)1.7;
            bungeeRunningWallChk.Checked = false;
            bungeeRunningWallWidthNum.Value = (decimal)0.45;
            bungeeRunningWallHeightNum.Value = (decimal)0.9;
            bungeeBlowerDistanceComment.Text = "Blower is no more than than 1.5m metres forward of the rear wall.";
            bungeeUserMaxMassComment.Text = "Markings show that max user mass is 120kg.";
            bungeeMinHeightComment.Text = "Markings show that minimum user height is 1.2m.";
            bungeeHarnessPullTestComment.Text = "Harness confirmed to max load of 2400n using calibrated crane scale.";
            bungeeCordLengthComment.Text = "Cord lengths are no longer than 3.3 metres.";
            bungeeCordDiametreComment.Text = "All cords are a minimum of 12.5mm in diametre.";
            bungeeTwoStageComment.Text = "Two stage locking system present.";
            bungeeBatonCompliantComment.Text = "Baton is easily held, located, released and placed by the user. ";
            bungeeLaneWidthComment.Text = "Each running lane is a maximum of 0.9m measured from inside wall to wall.";
            bungeeHarnessWidthComment.Text = "Harness is at least 200 millimetres wide.";
            bungeeRearWallComment.Text = "The rear wall is a minimum of 1.8m measured from the bed and a minimum of 600mm thick.";
            bungeeStartingPosWallsComment.Text = "The rear most section of the outside containment wall and the lane diver walls are a minimum of 1.7m in height and 1.5 in length.";
            bungeeRunningWallComment.Text = "The side running walls and dividing lane barriers are a minimum of 450mm thick and 0.9m tall (measured from the bed).";

            //Toddler / Play Zone
            playZoneIsPlayZoneChk.Checked = false;
            playZoneAgeMarkingChk.Checked = false;
            playZoneHeightMarkingChk.Checked = false;
            playZoneSightLineChk.Checked = false;
            playZoneAccessChk.Checked = false;
            playZoneSuitableMattingChk.Checked = false;
            playZoneTrafficChk.Checked = false;
            playZoneAirJugglerChk.Checked = false;
            playZoneBallsChk.Checked = false;
            playZoneBallPoolGapsChk.Checked = false;
            playZoneFittedSheetChk.Checked = false;
            playZoneBallPoolDepthChk.Checked = false;
            playZoneBallPoolEntryHeightChk.Checked = false;
            playZoneSlideGradChk.Checked = false;
            playZoneSlidePlatHeightChk.Checked = false;

            playZoneBallPoolDepthValue.Value = 450;
            playZoneBallPoolEntryHeightValue.Value = 630;
            playZoneSlideGradValue.Value = 64;
            playZoneSlidePlatHeightValue.Value = (decimal)1.5;

            playZoneAgeMarkingComment.Text = "Markings show that user age range is \"Approx. 1-3 years\".";
            playZoneHeightMarkingComment.Text = "Markings show that max user height is 1 meter.";
            playZoneSightLineComment.Text = "Unrestricted view possible for supervisors of all playing areas within the toddler//play zone itself.";
            playZoneAccessComment.Text = "Safe access for movement for carers and users. Steps easily negotiable.";
            playZoneSuitableMattingComment.Text = "Suitable impact absorbing matting is provided at the ends of slides, bouncing areas and ball pits. Matting is at least 20mm thick and covers entire base.";
            playZoneTrafficFlowComment.Text = "Pathways clear for user's to see path ahead. Design minimises and discourages lingering in pathways of forced motion and ball pits.";
            playZoneAirJugglerComment.Text = "Not sharp, pass probe test and do not form finger entrapment, not rigidly set and can collapse under pressure from any user.";
            playZoneBallsComment.Text = "Balls presented are a minimum of 60mm diameter and have a CE marking.";
            playZoneBallPoolGapsComment.Text = "No gaps present in ball pool that enable objects to become lodged, causing a hazard.";
            playZoneFittedSheetComment.Text = "Fitted base/ground sheet sewn in that prevents entrapment or accessing any underside area of walled/contained areas (such as ball pools).";
            playZoneBallPoolDepthComment.Text = "Ball Pool Depth is a maximum of 450mm or has a clearly marked max fill line.";
            playZoneBallPoolEntryHeightComment.Text = "The highest point of entry or accessible platform into the ball pool is no greater than a maximum of 630mm.";
            playZoneSlideGradComment.Text = "The slide platform gradient (access to the platform, not the slide gradient itself) is no greater than 64 degrees.";
            playZoneSlidePlatHeightComment.Text = "The slide platform height is no greater than 1.5m";

            //Ball Pool
            isToddlerBallPoolChk.Checked = false;
            tbpAgeRangeMarkingChk.Checked = false;
            tblMaxHeightMarkingsChk.Checked = false;
            tbpSuitableMattingChk.Checked = false;
            tbpAirJugglersCompliantChk.Checked = false;
            tbpBallsCompliantChk.Checked = false;
            tbpGapsChk.Checked = false;
            tbpFittedBaseChk.Checked = false;
            tbpBallPoolDepthChk.Checked = false;
            tbpBallPoolEntryChk.Checked = false;

            tbpBallPoolDepthValue.Value = 450;
            tbpBallPoolEntryValue.Value = 630;

            tbpAgeRangeMarkingComment.Text = "Markings show that user age range is \"Approx. 1-3 years\".";
            tpbMaxHeightMarkingsComment.Text = "Markings show that max user height is 1 meter.";
            tbpSuitableMattingComment.Text = "Suitable impact absorbing matting is provided for the base or directly underneith. Matting is at least 20mm thick and covers entire base.";
            tbpAirJugglersCompliantComment.Text = "Not sharp, pass probe test and do not form finger entrapment, not rigidly set and can collapse under pressure from any user.";
            tbpBallsCompliantComment.Text = "Balls presented are a minimum of 60mm diameter and have a CE marking.";
            tbpGapsComment.Text = "No gaps present in ball pool that enable objects to become lodged, causing a hazard.";
            tbpFittedBaseComment.Text = "Fitted base/ground sheet sewn in that prevents entrapment or accessing any underside area of walled/contained areas (such as ball pools).";
            tbpBallPoolDepthComment.Text = "Ball Pool Depth is a maximum of 450mm or has a clearly marked max fill line.";
            tbpBallPoolEntryComment.Text = "The highest point of entry or accessible platform into the ball pool is no greater than a maximum of 630mm.";

            //Inflatable Games
            isInflatableGameChk.Checked = false;
            gameMaxUserMassChk.Checked = false;
            gameAgeRangeMarkingChk.Checked = false;
            gameConstantAirFlowChk.Checked = false;
            gameDesignRiskChk.Checked = false;
            gameIntendedPlayRiskChk.Checked = false;
            gameAncillaryEquipmentChk.Checked = false;
            gameAncillaryEquipmentCompliantChk.Checked = false;
            gameContainingWallHeightChk.Checked = false;

            gameContainingWallHeightValue.Value = 0;

            gameTypeComment.Text = "";
            gameMaxUserMassComment.Text = "Markings show that max user mass is 120kg if the game has an inflatable bed.";
            gameAgeRangeMarkingComment.Text = "Skill based game - Age range is broad.";
            gameConstantAirFlowComment.Text = "Device requires constant air-flow and is not a sealed unit.";
            gameDesignRiskComment.Text = "Device design demonstrates clear intent to minimise risk to user.";
            gameIntendedPlayRiskComment.Text = "Intended play demonstrates that design minimises risk to user.";
            gameAncillaryEquipmentComment.Text = "No sharp edges, no excessive wear and no visual defects.";
            gameAncillaryEquipmentCompliantComment.Text = "Ancillary equipment provided by manufacturer OR is CE marked.";
            gameContainingWallHeightComment.Text = "Containing wall height (walls over 630mm) are a minimum of 0.9 meters.";

            //Catch-Bed
            isCatchBedChk.Checked = false;
            catchbedMaxUserMassMarkingChk.Checked = false;
            catchbedArrestChk.Checked = false;
            catchbedMattingChk.Checked = false;
            catchbedDesignRiskChk.Checked = false;
            catchbedIntendedPlayChk.Checked = false;
            catchbedAncillaryFitChk.Checked = false;
            catchbedAncillaryCompliantChk.Checked = false;
            catchbedApronChk.Checked = false;
            catchbedTroughChk.Checked = false;
            catchbedFrameworkChk.Checked = false;
            catchbedGroundingChk.Checked = false;
            catchbedBedHeightChk.Checked = false;
            catchbedPlatformFallDistanceChk.Checked = false;
            catchbedBlowerTubeLengthChk.Checked = false;

            catchbedTypeOfUnitComment.Text = "";
            catchbedMaxUserMassMarkingComment.Text = "Markings show that max user mass is 120kg.";
            catchbedArrestComment.Text = "Catch-Bed is suitable to arrest, hold and protect users when falling onto or into it. ";
            catchbedMattingComment.Text = "Suitable impact absorbing matting is presented at time of inspection. Matting is at least 20mm thick.";
            catchbedDesignRiskComment.Text = "Device design demonstrates clear intent to minimise risk to user.";
            catchbedIntendedPlayRiskComment.Text = "Intended play demonstrates that design minimises risk to user.";
            catchbedAncillaryFitComment.Text = "No sharp edges, no excessive wear and no visual defects.";
            catchbedAncillaryCompliantComment.Text = "Ancillary equipment provided by manufacturer OR is CE marked.";
            catchbedApronComment.Text = "Where applicable a suitable apron is present including padding around any framework or hard object. ";
            catchbedTroughDepthComment.Text = "Trough depth is no greater than 70mm or is otherwise covered by a sheet.";
            catchbedFrameworkComment.Text = "Framework not part of this inspection and not presented. Not applicable to this inspection, only inspecting inflatable device. Separate inspection required for mechanical device.";
            catchbedGroundingComment.Text = "Grounding test passed the required 120kg inspection method (Rodeo Bull, Wipeout, Lastman Standing, Surf Sim).";
            catchbedBedHeightComment.Text = "Bed Height is a minimum of 400 mm (Rodeo Bull, Wipeout, Lastman Standing, Surf Sim)";
            catchbedPlatformFallDistanceComment.Text = "Distance from the near-side edge of platform to the inside edge of containing wall is 1.8m.";
            catchbedBlowerTubeLengthComment.Text = "Inflate blower tube is at least 2.5m from edge of cone to inflatable on the open walled side due to flat-bed open wall.";

            catchbedBedHeightValue.Value = 400;
            catchbedPlatformFallDistanceValue.Value = (decimal)1.80;
            catchbedBlowerTubeLengthValue.Value = (decimal)2.50;

            //Slide
            isSlideChk.Checked = false;
            slidePlatformHeightValue.Value = (decimal)3.00;
            slidePlatformHeightComment.Text = "";
            slideWallHeightValue.Value = (decimal)1.00;
            slideWallHeightComment.Text = "Lowest wall height taken from the slide platform height and/or permanently roofed.";
            slidefirstmetreHeightValue.Value = (decimal)1.00;
            slideFirstMetreHeightComment.Text = "";
            beyondfirstmetreHeightValue.Value = (decimal)0.5;
            beyondfirstmetreHeightComment.Text = "";
            slidePermRoofedCheck.Checked = false;
            slidePermRoofedComment.Text = "";
            runoutValue.Value = (decimal)1.50;
            runOutPassFail.Checked = false;
            runoutComment.Text = "Slide Run-out is at least 50% of slide platform height.";
            slipsheetPassFail.Checked = false;
            slipsheetComment.Text = "Slip sheet has no tears, causes no entrapment and is securely fastened.";

            //Totally Enclosed
            isUnitEnclosedChk.Checked = false;
            exitNumberValue.Value = 0;
            exitNumberPassFail.Checked = false;
            exitNumberComment.Text = "More than one exit if user count > 15 and user never more than 5m away from exit.";
            exitsignVisiblePassFail.Checked = false;
            exitSignVisibleComment.Text = "Exit sign is always visible and user never more than 5m away from exit.";

            //User Height/Count
            containingWallHeightValue.Value = (decimal)1.20;
            containingWallHeightComment.Text = "Lowest wall height taken from adjacent platform.";
            platformHeightValue.Value = (decimal)0.60;
            platformHeightComment.Text = "";
            slidebarrierHeightValue.Value = (decimal)1.00;
            slideBarrierHeightComment.Text = "";
            remainingSlideWallHeightValue.Value = (decimal)0.50;
            remainingSlideWallHeightComment.Text = "";
            permanentRoofChecked.Checked = false;
            permRoofComment.Text = "";
            userHeight.Value = (decimal)1.00;
            userHeightComment.Text = "Calculated using lowest containing wall height minus the platform height or the relevant slide calculations where appropriate.";
            playAreaLengthValue.Value = (decimal)1.00;
            playAreaLengthComment.Text = "";
            playAreaWidthValue.Value = (decimal)1.00;
            playAreaWidthComment.Text = "";
            negAdjustmentValue.Value = (decimal)0.00;
            negAdjustmentComment.Text = "Approx square metre taken by obstacles, biff bash, mounds etc.";
            usersat1000mm.Value = 0;
            usersat1200mm.Value = 0;
            usersat1500mm.Value = 0;
            usersat1800mm.Value = 0;

            //Structure 
            seamIntegrityPassFail.Checked = false;
            seamIntegrityComment.Text = "Secure and no loose stitching.";
            lockstitchPassFail.Checked = false;
            lockStitchComment.Text = "Lock stitching used.";
            stitchLengthValue.Value = 4;
            stitchLengthPassFail.Checked = false;
            stitchLengthComment.Text = "Stitching between 3mm - 8mm";
            airLossPassFail.Checked = false;
            airLossComment.Text = "No significant air loss or unintended holes.";
            wallStraightPassFail.Checked = false;
            wallStraightComment.Text = "Walls Vertical and gradient no greater than +-5% where intended.";
            sharpEdgesPassFail.Checked = false;
            sharpEdgesComment.Text = "No sharp or pointed edges in play area or easily accessible.";
            stablePassFail.Checked = false;
            stableComment.Text = "Unit is stable.";
            evacTime.Value = 30;
            evacTimePassFail.Checked = false;
            evacTimeComment.Text = "Evacuation time sufficient for intended users to exit safely under supervision.";

            //Structure Cont
            stepSizeValue.Value = (decimal)1.20;
            stepSizePassFail.Checked = false;
            stepSizeComment.Text = "Step/Ramp tread depth is equal to or more then 1.5 times the adjacent attached playing area.";
            falloffHeight.Value = (decimal)0.60;
            falloffHeightPassFail.Checked = false;
            falloffHeightComment.Text = "Critical Fall Off Height is a max of 0.6m";
            pressureValue.Value = (decimal)1.00;
            pressurePassFail.Checked = false;
            pressureComment.Text = "Pressure is a minimum of 1.0 KPA";
            troughDepthValue.Value = 70;
            troughWidthValue.Value = 470;
            troughPassFail.Checked = false;
            troughComment.Text = "Trough Depth is no more than one third (1/3) of the adjacent panel width.";
            entrapPassFail.Checked = false;
            entrapComment.Text = "No entrapments.";
            markingsPassFail.Checked = false;
            markingsComment.Text = "Blower, User Height, Max Users, Unique ID, Year of Manufacture & Address and Standard Version.";
            groundingPassFail.Checked = false;
            groundingComment.Text = "25kg @ 1m, 35kg @ 1.2m, 65kg @ 1.5m and 85kg @ 1.8m";

            //Anchorage
            numLowAnchors.Value = 6;
            numHighAnchors.Value = 0;
            numAnchorsPassFail.Checked = false;
            numAnchorsComment.Text = "Calculated sufficient number of anchor points per side.";
            anchorAccessoriesPassFail.Checked = false;
            AnchorAccessoriesComment.Text = "Produced correct amount of stakes at 380mmx16mm with rounded top and no visible cracks.";
            anchorDegreePassFail.Checked = false;
            anchorDegreesComment.Text = "Anchors are at an angle to the ground of 30° to 45°";
            anchorTypePassFail.Checked = false;
            anchorTypeComment.Text = "Metal and permanently closed.";
            pullStrengthPassFail.Checked = false;
            pullStrengthComment.Text = "Meets the 1600 newton pull requirement test using 163kg pull system";

            //Materials
            ropesizeValue.Value = 18;
            ropeSizePassFail.Checked = false;
            ropeSizeComment.Text = "Between 18mm - 45mm. Fixed at both ends, no greater than 20% swing to prevent strangulation.";
            clamberPassFail.Checked = false;
            clamberComment.Text = "Not monofilament, no entrapment and at least 12mm diameter, securely knotted and no fraying, securely fastened.";
            retentionNettingPassFail.Checked = false;
            retentionNettingComment.Text = "Vertical netting > 1m mesh size is no greater than 30mm. Roof neeting mesh size no greater than 8mm.";
            zipsPassFail.Checked = false;
            zipsComment.Text = "Zips easily open/close and covered. Open both sides where applicable.";
            windowsPassFail.Checked = false;
            windowsComment.Text = "Retention netting strong enough to support heaviest user for whom it is designed. No entrapment.";
            artworkPassFail.Checked = false;
            artworkComment.Text = "Not flaking - Manufacturer to supply conformity report to EN 71-3";
            threadPassFail.Checked = false;
            threadComment.Text = "Manufacturer to provide conformity report to confirm thread is non-rotting yarn and has a tensile strength of 88 newtons.";
            fabricPassFail.Checked = false;
            fabricComment.Text = "Manufacturer to provide conformity report to confirm tensile strength of 1850 and tear stength of 350 newtons.";
            fireRetardentPassFail.Checked = false;
            fireRetardentComment.Text = "Manufacturer to provide conformity report to confirm FR.";

            //Fan
            blowerSizeComment.Text = "Reaches 1.0 kpa pressure on a 1.5hp blower.";
            blowerFlapPassFail.Checked = false;
            blowerFlapComment.Text = "Blower return flap present and correct to reduce deflation time.";
            blowerFingerPassFail.Checked = false;
            blowerFingerComment.Text = "8mm finger probe does not pass and come into contact with any hot or moving part.";
            patPassFail.Checked = false;
            patComment.Text = "Customer own certificate.";
            blowerVisualPassFail.Checked = false;
            blowerVisualComment.Text = "Passes visual inspection and suitable.";
            blowerSerial.Text = "";

            //Risk Assessment
            riskAssessmentNotes.Text =
                "The suitability of all materials used in manufacturing should be taken from conformity reports. " +
                "Where not available these should be requested from the manufacturer/importer. \r\n" +
                "Safety aspects should be taken from the user manual provided by the manufacturer. " +
                "If not provided then this should be requested or created by the controller.\r\n" +
                "Not to be used in wind speeds in excess of 38Kph.\r\n" +
                "A competent adult should supervise the inflatable and users at all times.\r\n" +
                "All anchor points to be used at all times.\r\n";


            //Additional Images
            AdditionalPic1.Image = null;
            AdditionalPic2.Image = null;
            AdditionalPic3.Image = null;
            AdditionalPic4.Image = null;

            //Operator Manual
            operatorManualChk.Checked = false;

            //Indoor Only
            indoorOnlyChk.Checked = false;

            //Pipa Integrator
            PIPATagNum.Value = 0;
        }

        void clearRecords()
        {
            records.Rows.Clear();
        }


        void deleteRowRecord(int reportNum, int rowIndex)
        {
            try
            {
                SQLiteConnection sqlite_conn = CreateConnection();
                string query = "DELETE FROM Inspections WHERE TagID = " + reportNum.ToString() + ";";

                SQLiteCommand sqlite_cmd;
                sqlite_cmd = sqlite_conn.CreateCommand();
                sqlite_cmd.CommandText = query;

                sqlite_cmd.ExecuteNonQuery();

                sqlite_conn.Close();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, toolName);
            }

            //MessageBox.Show("deleting report number " + reportNum.ToString() + " and removing row " + rowIndex.ToString(), toolName);
            records.Rows.RemoveAt(rowIndex);

        }

        /*
         * Here is where I now load the values from the datagridview into the Application's tools and controls. 
         * I did consider sending a new SQL Query and getting the data from the source, using the Unique Report ID in the WHERE clause of the query
         * Which would be good, rather than pulling it from the SQL database to the datagridview and then from there sending it to the application
         * But I considered the I/O operation on the disk and how this would be affected at scale, plus I couldn't be bothered.
         */
        void loadReportIntoApplication(int rowIndex)
        {
            try
            {
                //Global Details Tab
                unitPic.Image = (Image)records.Rows[rowIndex].Cells[1].FormattedValue; //Can't believe that worked. I thought for sure I would need to convert the image to a string, then convert to an image. 
                InspectionCompName.Text = records.Rows[rowIndex].Cells[2].Value.ToString();
                //Do not load the date - You want to re-inspect so the date will be today. (handy really, because I didn't fancy converting from a string to the date time picker type)
                rpiiReg.Text = records.Rows[rowIndex].Cells[4].Value.ToString();
                inspectionLocation.Text = records.Rows[rowIndex].Cells[5].Value.ToString();

                //Unit Details Tab
                unitDescriptionText.Text = records.Rows[rowIndex].Cells[6].Value.ToString();
                ManufacturerText.Text = records.Rows[rowIndex].Cells[7].Value.ToString();
                unitWidthNum.Value = (decimal)records.Rows[rowIndex].Cells[8].Value;
                unitLengthNum.Value = (decimal)records.Rows[rowIndex].Cells[9].Value;
                unitHeightNum.Value = (decimal)records.Rows[rowIndex].Cells[10].Value;
                serialText.Text = records.Rows[rowIndex].Cells[11].Value.ToString();
                unitTypeText.Text = records.Rows[rowIndex].Cells[12].Value.ToString();
                unitOwnerText.Text = records.Rows[rowIndex].Cells[13].Value.ToString();

                //User Height/Count Tab
                containingWallHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[14].Value;
                containingWallHeightComment.Text = records.Rows[rowIndex].Cells[15].Value.ToString();
                platformHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[16].Value;
                platformHeightComment.Text = records.Rows[rowIndex].Cells[17].Value.ToString();
                slidebarrierHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[18].Value;
                slideBarrierHeightComment.Text = records.Rows[rowIndex].Cells[19].Value.ToString();
                remainingSlideWallHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[20].Value;
                remainingSlideWallHeightComment.Text = records.Rows[rowIndex].Cells[21].Value.ToString();
                permanentRoofChecked.Checked = (bool)records.Rows[rowIndex].Cells[22].FormattedValue; //Formatted value is actually the tits! Safe to cast to bool this way, because it is a boolean as a formatted value anyway.
                permRoofComment.Text = records.Rows[rowIndex].Cells[23].Value.ToString();
                userHeight.Value = (decimal)records.Rows[rowIndex].Cells[24].Value;
                userHeightComment.Text = records.Rows[rowIndex].Cells[25].Value.ToString();
                playAreaLengthValue.Value = (decimal)records.Rows[rowIndex].Cells[26].Value;
                playAreaLengthComment.Text = records.Rows[rowIndex].Cells[27].Value.ToString();
                playAreaWidthValue.Value = (decimal)records.Rows[rowIndex].Cells[28].Value;
                playAreaWidthComment.Text = records.Rows[rowIndex].Cells[29].Value.ToString();
                negAdjustmentValue.Value = (decimal)records.Rows[rowIndex].Cells[30].Value;
                negAdjustmentComment.Text = records.Rows[rowIndex].Cells[31].Value.ToString();
                usersat1000mm.Value = (int)records.Rows[rowIndex].Cells[32].Value;
                usersat1200mm.Value = (int)records.Rows[rowIndex].Cells[33].Value;
                usersat1500mm.Value = (int)records.Rows[rowIndex].Cells[34].Value;
                usersat1800mm.Value = (int)records.Rows[rowIndex].Cells[35].Value;

                //Slide Tab
                isSlideChk.Checked = (bool)records.Rows[rowIndex].Cells[36].FormattedValue;
                slidePlatformHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[37].Value;
                slidePlatformHeightComment.Text = records.Rows[rowIndex].Cells[38].Value.ToString();
                slideWallHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[39].Value;
                slideWallHeightComment.Text = records.Rows[rowIndex].Cells[40].Value.ToString();
                slidefirstmetreHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[41].Value;
                slideFirstMetreHeightComment.Text = records.Rows[rowIndex].Cells[42].Value.ToString();
                beyondfirstmetreHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[43].Value;
                beyondfirstmetreHeightComment.Text = records.Rows[rowIndex].Cells[44].Value.ToString();
                slidePermRoofedCheck.Checked = (bool)records.Rows[rowIndex].Cells[45].FormattedValue;
                slidePermRoofedComment.Text = records.Rows[rowIndex].Cells[46].Value.ToString();
                clamberNettingPassFail.Checked = (bool)records.Rows[rowIndex].Cells[47].FormattedValue;
                clamberNettingComment.Text = records.Rows[rowIndex].Cells[48].Value.ToString();
                runoutValue.Value = (decimal)records.Rows[rowIndex].Cells[49].Value;
                runOutPassFail.Checked = (bool)records.Rows[rowIndex].Cells[50].FormattedValue;
                runoutComment.Text = records.Rows[rowIndex].Cells[51].Value.ToString();
                slipsheetPassFail.Checked = (bool)records.Rows[rowIndex].Cells[52].FormattedValue;
                slipsheetComment.Text = records.Rows[rowIndex].Cells[53].Value.ToString();

                //Structure Tab
                seamIntegrityPassFail.Checked = (bool)records.Rows[rowIndex].Cells[54].FormattedValue;
                seamIntegrityComment.Text = records.Rows[rowIndex].Cells[55].Value.ToString();
                lockstitchPassFail.Checked = (bool)records.Rows[rowIndex].Cells[56].FormattedValue;
                lockStitchComment.Text = records.Rows[rowIndex].Cells[57].Value.ToString();
                stitchLengthValue.Value = (int)records.Rows[rowIndex].Cells[58].Value;
                stitchLengthPassFail.Checked = (bool)records.Rows[rowIndex].Cells[59].FormattedValue;
                stitchLengthComment.Text = records.Rows[rowIndex].Cells[60].Value.ToString();
                airLossPassFail.Checked = (bool)records.Rows[rowIndex].Cells[61].FormattedValue;
                airLossComment.Text = records.Rows[rowIndex].Cells[62].Value.ToString();
                wallStraightPassFail.Checked = (bool)records.Rows[rowIndex].Cells[63].FormattedValue;
                wallStraightComment.Text = records.Rows[rowIndex].Cells[64].Value.ToString();
                sharpEdgesPassFail.Checked = (bool)records.Rows[rowIndex].Cells[65].FormattedValue;
                sharpEdgesComment.Text = records.Rows[rowIndex].Cells[66].Value.ToString();
                tubeDistanceValue.Value = (decimal)records.Rows[rowIndex].Cells[67].Value;
                tubeDistancePassFail.Checked = (bool)records.Rows[rowIndex].Cells[68].FormattedValue;
                tubeDistanceComment.Text = records.Rows[rowIndex].Cells[69].Value.ToString();
                stablePassFail.Checked = (bool)records.Rows[rowIndex].Cells[70].FormattedValue;
                stableComment.Text = records.Rows[rowIndex].Cells[71].Value.ToString();
                evacTime.Value = (int)records.Rows[rowIndex].Cells[72].Value;
                evacTimePassFail.Checked = (bool)records.Rows[rowIndex].Cells[73].FormattedValue;
                evacTimeComment.Text = records.Rows[rowIndex].Cells[74].Value.ToString();

                //Structure Cont. Tab
                stepSizeValue.Value = (decimal)records.Rows[rowIndex].Cells[75].Value;
                stepSizePassFail.Checked = (bool)records.Rows[rowIndex].Cells[76].FormattedValue;
                stepSizeComment.Text = records.Rows[rowIndex].Cells[77].Value.ToString();
                falloffHeight.Value = (decimal)records.Rows[rowIndex].Cells[78].Value;
                falloffHeightPassFail.Checked = (bool)records.Rows[rowIndex].Cells[79].FormattedValue;
                falloffHeightComment.Text = records.Rows[rowIndex].Cells[80].Value.ToString();
                pressureValue.Value = (decimal)records.Rows[rowIndex].Cells[81].Value;
                pressurePassFail.Checked = (bool)records.Rows[rowIndex].Cells[82].FormattedValue;
                pressureComment.Text = records.Rows[rowIndex].Cells[83].Value.ToString();

                troughDepthValue.Value = (decimal)records.Rows[rowIndex].Cells[84].Value;
                troughWidthValue.Value = (decimal)records.Rows[rowIndex].Cells[85].Value;
                troughPassFail.Checked = (bool)records.Rows[rowIndex].Cells[86].FormattedValue;
                troughComment.Text = records.Rows[rowIndex].Cells[87].Value.ToString();
                entrapPassFail.Checked = (bool)records.Rows[rowIndex].Cells[88].FormattedValue;
                entrapComment.Text = records.Rows[rowIndex].Cells[89].Value.ToString();
                markingsPassFail.Checked = (bool)records.Rows[rowIndex].Cells[90].FormattedValue;
                markingsComment.Text = records.Rows[rowIndex].Cells[91].Value.ToString();
                groundingPassFail.Checked = (bool)records.Rows[rowIndex].Cells[92].FormattedValue;
                groundingComment.Text = records.Rows[rowIndex].Cells[93].Value.ToString();

                //Anchorage
                numLowAnchors.Value = (int)records.Rows[rowIndex].Cells[94].Value;
                numHighAnchors.Value = (int)records.Rows[rowIndex].Cells[95].Value;
                numAnchorsPassFail.Checked = (bool)records.Rows[rowIndex].Cells[96].FormattedValue;
                numAnchorsComment.Text = records.Rows[rowIndex].Cells[97].Value.ToString();
                anchorAccessoriesPassFail.Checked = (bool)records.Rows[rowIndex].Cells[98].FormattedValue;
                AnchorAccessoriesComment.Text = records.Rows[rowIndex].Cells[99].Value.ToString();
                anchorDegreePassFail.Checked = (bool)records.Rows[rowIndex].Cells[100].FormattedValue;
                anchorDegreesComment.Text = records.Rows[rowIndex].Cells[101].Value.ToString();
                anchorTypePassFail.Checked = (bool)records.Rows[rowIndex].Cells[102].FormattedValue;
                anchorTypeComment.Text = records.Rows[rowIndex].Cells[103].Value.ToString();
                pullStrengthPassFail.Checked = (bool)records.Rows[rowIndex].Cells[104].FormattedValue;
                pullStrengthComment.Text = records.Rows[rowIndex].Cells[105].Value.ToString();

                //Totally Enclosed Tab
                isUnitEnclosedChk.Checked = (bool)records.Rows[rowIndex].Cells[106].FormattedValue;
                exitNumberValue.Value = (int)records.Rows[rowIndex].Cells[107].Value;
                exitNumberPassFail.Checked = (bool)records.Rows[rowIndex].Cells[108].FormattedValue;
                exitNumberComment.Text = records.Rows[rowIndex].Cells[109].Value.ToString();
                exitsignVisiblePassFail.Checked = (bool)records.Rows[rowIndex].Cells[110].FormattedValue;
                exitSignVisibleComment.Text = records.Rows[rowIndex].Cells[111].Value.ToString();

                //Materials Tab
                ropesizeValue.Value = (int)records.Rows[rowIndex].Cells[112].Value;
                ropeSizePassFail.Checked = (bool)records.Rows[rowIndex].Cells[113].FormattedValue;
                ropeSizeComment.Text = records.Rows[rowIndex].Cells[114].Value.ToString();
                clamberPassFail.Checked = (bool)records.Rows[rowIndex].Cells[115].FormattedValue;
                clamberComment.Text = records.Rows[rowIndex].Cells[116].Value.ToString();
                retentionNettingPassFail.Checked = (bool)records.Rows[rowIndex].Cells[117].FormattedValue;
                retentionNettingComment.Text = records.Rows[rowIndex].Cells[118].Value.ToString();
                zipsPassFail.Checked = (bool)records.Rows[rowIndex].Cells[119].FormattedValue;
                zipsComment.Text = records.Rows[rowIndex].Cells[120].Value.ToString();
                windowsPassFail.Checked = (bool)records.Rows[rowIndex].Cells[121].FormattedValue;
                windowsComment.Text = records.Rows[rowIndex].Cells[122].Value.ToString();
                artworkPassFail.Checked = (bool)records.Rows[rowIndex].Cells[123].FormattedValue;
                artworkComment.Text = records.Rows[rowIndex].Cells[124].Value.ToString();
                threadPassFail.Checked = (bool)records.Rows[rowIndex].Cells[125].FormattedValue;
                threadComment.Text = records.Rows[rowIndex].Cells[126].Value.ToString();
                fabricPassFail.Checked = (bool)records.Rows[rowIndex].Cells[127].FormattedValue;
                fabricComment.Text = records.Rows[rowIndex].Cells[128].Value.ToString();
                fireRetardentPassFail.Checked = (bool)records.Rows[rowIndex].Cells[129].FormattedValue;
                fireRetardentComment.Text = records.Rows[rowIndex].Cells[130].Value.ToString();

                //Fan Tab
                blowerSizeComment.Text = records.Rows[rowIndex].Cells[131].Value.ToString();
                blowerFlapPassFail.Checked = (bool)records.Rows[rowIndex].Cells[132].FormattedValue;
                blowerFlapComment.Text = records.Rows[rowIndex].Cells[133].Value.ToString();
                blowerFingerPassFail.Checked = (bool)records.Rows[rowIndex].Cells[134].FormattedValue;
                blowerFingerComment.Text = records.Rows[rowIndex].Cells[135].Value.ToString();
                patPassFail.Checked = (bool)records.Rows[rowIndex].Cells[136].FormattedValue;
                patComment.Text = records.Rows[rowIndex].Cells[137].Value.ToString();
                blowerVisualPassFail.Checked = (bool)records.Rows[rowIndex].Cells[138].FormattedValue;
                blowerVisualComment.Text = records.Rows[rowIndex].Cells[139].Value.ToString();
                blowerSerial.Text = records.Rows[rowIndex].Cells[140].Value.ToString();

                //Risk Assessment Tab
                riskAssessmentNotes.Text = records.Rows[rowIndex].Cells[141].Value.ToString();

                //Passed Inspection
                passedRadio.Checked = (bool)records.Rows[rowIndex].Cells[142].FormattedValue; //Should automatically adjust the failed check

                //Testimony
                testimony.Text = records.Rows[rowIndex].Cells[143].Value.ToString(); //Not really sure why I am loading this - It's static and read only. However, I suppose it may be updated in the future.

                //Additional Images Tab
                AdditionalPic1.Image = (Image)records.Rows[rowIndex].Cells[144].FormattedValue;
                AdditionalPic2.Image = (Image)records.Rows[rowIndex].Cells[145].FormattedValue;
                AdditionalPic3.Image = (Image)records.Rows[rowIndex].Cells[146].FormattedValue;
                AdditionalPic4.Image = (Image)records.Rows[rowIndex].Cells[147].FormattedValue;

                //Operator Manual
                operatorManualChk.Checked = (bool)records.Rows[rowIndex].Cells[148].FormattedValue;

                //Bungee
                isBungeeRunChk.Checked = (bool)records.Rows[rowIndex].Cells[149].FormattedValue; //is a bungee check
                bungeeBlowerDistanceChk.Checked = (bool)records.Rows[rowIndex].Cells[150].FormattedValue; //bungee blower forward distance pass
                bungeeBlowerDistanceComment.Text = records.Rows[rowIndex].Cells[151].Value.ToString(); //bungee blower forward distance comment
                bungeeMaxMassChk.Checked = (bool)records.Rows[rowIndex].Cells[152].FormattedValue; // bungee markings max mass pass
                bungeeUserMaxMassComment.Text = records.Rows[rowIndex].Cells[153].Value.ToString(); // bungee marking max user mass marking comment
                bungeeMinHeightChk.Checked = (bool)records.Rows[rowIndex].Cells[154].FormattedValue; // bungee marking minimum user height pass
                bungeeMinHeightComment.Text = records.Rows[rowIndex].Cells[155].Value.ToString(); // bungee marking min user height marking comment
                bungeePullTestChk.Checked = (bool)records.Rows[rowIndex].Cells[156].FormattedValue; // bungee pull strength pass
                bungeeHarnessPullTestComment.Text = records.Rows[rowIndex].Cells[157].Value.ToString(); // bungee pull strength pass comment
                bungeeCordLengthChk.Checked = (bool)records.Rows[rowIndex].Cells[158].FormattedValue; // bungee Cord Length Max Pass
                bungeeCordLengthComment.Text = records.Rows[rowIndex].Cells[159].Value.ToString(); // bungee Cord Length Max Comment
                bungeeCordDiametreChk.Checked = (bool)records.Rows[rowIndex].Cells[160].FormattedValue; // bungee Cord Diametre Min Pass
                bungeeCordDiametreComment.Text = records.Rows[rowIndex].Cells[161].Value.ToString(); // bungee Cord Diametre Min Comment
                bungeeTwoStageChk.Checked = (bool)records.Rows[rowIndex].Cells[162].FormattedValue; // bungee Two Stage Locking Pass
                bungeeTwoStageComment.Text = records.Rows[rowIndex].Cells[163].Value.ToString(); // bungee Two Stage Locking Comment
                bungeeBatonCompliantChk.Checked = (bool)records.Rows[rowIndex].Cells[164].FormattedValue; // bungee Baton Compliant Pass
                bungeeBatonCompliantComment.Text = records.Rows[rowIndex].Cells[165].Value.ToString(); // bungee Baton Compliant Comment
                bungeeLaneWidthChk.Checked = (bool)records.Rows[rowIndex].Cells[166].FormattedValue; // bungee Lane Width Max Pass
                bungeeLaneWidthComment.Text = records.Rows[rowIndex].Cells[167].Value.ToString(); // bungee Lane Width Max Comment
                bungeeHarnessWidth.Value = (int)records.Rows[rowIndex].Cells[168].Value; // bungee harness width
                bungeeHarnessWidthPassChk.Checked = (bool)records.Rows[rowIndex].Cells[169].FormattedValue; // bungee harness width pass
                bungeeHarnessWidthComment.Text = records.Rows[rowIndex].Cells[170].Value.ToString(); // bungee harness width comment
                bungeeCordAmount.Value = (int)records.Rows[rowIndex].Cells[171].Value; // bungee numb of cords
                bungeeRearWallWidthNum.Value = (decimal)records.Rows[rowIndex].Cells[172].Value; // bungee Rear Wall Thickness Value
                bungeeRearWallHeight.Value = (decimal)records.Rows[rowIndex].Cells[173].Value; // bungee Rear Wall Height Value
                bungeeRearWallChk.Checked = (bool)records.Rows[rowIndex].Cells[174].FormattedValue; // bungee Rear Wall Pass
                bungeeRearWallComment.Text = records.Rows[rowIndex].Cells[175].Value.ToString(); // bungee Rear Wall Comment
                bungeeStartingPosWallsLengthNum.Value = (decimal)records.Rows[rowIndex].Cells[176].Value; // bungee Side Wall Length Value
                bungeeStartingPosWallsHeightNum.Value = (decimal)records.Rows[rowIndex].Cells[177].Value; // bungee Side Wall Height Value
                bungeeStartingPosWallChk.Checked = (bool)records.Rows[rowIndex].Cells[178].FormattedValue; // bungee Side Wall Pass
                bungeeStartingPosWallsComment.Text = records.Rows[rowIndex].Cells[179].Value.ToString(); // bungee Side Wall Comment
                bungeeRunningWallWidthNum.Value = (decimal)records.Rows[rowIndex].Cells[180].Value; // bungee Running Wall Width Value
                bungeeRunningWallHeightNum.Value = (decimal)records.Rows[rowIndex].Cells[181].Value; // bungee Running Wall Height Value
                bungeeRunningWallChk.Checked = (bool)records.Rows[rowIndex].Cells[182].FormattedValue; // bungee Running Wall Pass
                bungeeRunningWallComment.Text = records.Rows[rowIndex].Cells[183].Value.ToString(); // bungee Running Wall Comment

                //Toddler/Play Zone
                playZoneIsPlayZoneChk.Checked = (bool)records.Rows[rowIndex].Cells[184].FormattedValue; //is a toddler / play zone check
                playZoneAgeMarkingChk.Checked = (bool)records.Rows[rowIndex].Cells[185].FormattedValue; //Marking present to indicate age range?
                playZoneAgeMarkingComment.Text = records.Rows[rowIndex].Cells[186].Value.ToString(); //playZoneAgeMarkingComment
                playZoneHeightMarkingChk.Checked = (bool)records.Rows[rowIndex].Cells[187].FormattedValue; //playZoneHeightMarkingChk
                playZoneHeightMarkingComment.Text = records.Rows[rowIndex].Cells[188].Value.ToString(); //playZoneHeightMarkingComment
                playZoneSightLineChk.Checked = (bool)records.Rows[rowIndex].Cells[189].FormattedValue; //playZoneSightLineChk
                playZoneSightLineComment.Text = records.Rows[rowIndex].Cells[190].Value.ToString(); //playZoneSightLineComment
                playZoneAccessChk.Checked = (bool)records.Rows[rowIndex].Cells[191].FormattedValue; //playZoneAccessChk
                playZoneAccessComment.Text = records.Rows[rowIndex].Cells[192].Value.ToString(); //playZoneAccessComment
                playZoneSuitableMattingChk.Checked = (bool)records.Rows[rowIndex].Cells[193].FormattedValue; //playZoneSuitableMattingChk
                playZoneSuitableMattingComment.Text = records.Rows[rowIndex].Cells[194].Value.ToString(); //playZoneSuitableMattingComment
                playZoneTrafficChk.Checked = (bool)records.Rows[rowIndex].Cells[195].FormattedValue; //playZoneTrafficChk
                playZoneTrafficFlowComment.Text = records.Rows[rowIndex].Cells[196].Value.ToString(); //playZoneTrafficFlowComment
                playZoneAirJugglerChk.Checked = (bool)records.Rows[rowIndex].Cells[197].FormattedValue; //playZoneAirJugglerChk
                playZoneAirJugglerComment.Text = records.Rows[rowIndex].Cells[198].Value.ToString(); //playZoneAirJugglerComment
                playZoneBallsChk.Checked = (bool)records.Rows[rowIndex].Cells[199].FormattedValue; //playZoneBallsChk
                playZoneBallsComment.Text = records.Rows[rowIndex].Cells[200].Value.ToString(); //playZoneBallsComment
                playZoneBallPoolGapsChk.Checked = (bool)records.Rows[rowIndex].Cells[201].FormattedValue; //playZoneBallPoolGapsChk
                playZoneBallPoolGapsComment.Text = records.Rows[rowIndex].Cells[202].Value.ToString(); //playZoneBallPoolGapsComment
                playZoneFittedSheetChk.Checked = (bool)records.Rows[rowIndex].Cells[203].FormattedValue; //playZoneFittedSheetChk
                playZoneFittedSheetComment.Text = records.Rows[rowIndex].Cells[204].Value.ToString(); //playZoneFittedSheetComment
                playZoneBallPoolDepthValue.Value = (int)records.Rows[rowIndex].Cells[205].Value; //playZoneBallPoolDepthValue
                playZoneBallPoolDepthChk.Checked = (bool)records.Rows[rowIndex].Cells[206].FormattedValue; //playZoneBallPoolDepthChk
                playZoneBallPoolDepthComment.Text = records.Rows[rowIndex].Cells[207].Value.ToString(); //playZoneBallPoolDepthComment
                playZoneBallPoolEntryHeightValue.Value = (int)records.Rows[rowIndex].Cells[208].Value; //playZoneBallPoolEntryHeightValue
                playZoneBallPoolEntryHeightChk.Checked = (bool)records.Rows[rowIndex].Cells[209].FormattedValue; //playZoneBallPoolEntryHeightChk
                playZoneBallPoolEntryHeightComment.Text = records.Rows[rowIndex].Cells[210].Value.ToString(); //playZoneBallPoolEntryHeightComment
                playZoneSlideGradValue.Value = (int)records.Rows[rowIndex].Cells[211].Value; //playZoneSlideGradValue
                playZoneSlideGradChk.Checked = (bool)records.Rows[rowIndex].Cells[212].FormattedValue; //playZoneSlideGradChk
                playZoneSlideGradComment.Text = records.Rows[rowIndex].Cells[213].Value.ToString(); //playZoneSlideGradComment
                playZoneSlidePlatHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[214].Value; //playZoneSlidePlatHeightValue
                playZoneSlidePlatHeightChk.Checked = (bool)records.Rows[rowIndex].Cells[215].FormattedValue; //playZoneSlidePlatHeightChk
                playZoneSlidePlatHeightComment.Text = records.Rows[rowIndex].Cells[216].Value.ToString(); //playZoneSlidePlatHeightComment

                //Inflatable Ball Pool
                isToddlerBallPoolChk.Checked = (bool)records.Rows[rowIndex].Cells[217].FormattedValue;
                tbpAgeRangeMarkingChk.Checked = (bool)records.Rows[rowIndex].Cells[218].FormattedValue;
                tbpAgeRangeMarkingComment.Text = records.Rows[rowIndex].Cells[219].Value.ToString();
                tblMaxHeightMarkingsChk.Checked = (bool)records.Rows[rowIndex].Cells[220].FormattedValue;
                tpbMaxHeightMarkingsComment.Text = records.Rows[rowIndex].Cells[221].Value.ToString();
                tbpSuitableMattingChk.Checked = (bool)records.Rows[rowIndex].Cells[222].FormattedValue;
                tbpSuitableMattingComment.Text = records.Rows[rowIndex].Cells[223].Value.ToString();
                tbpAirJugglersCompliantChk.Checked = (bool)records.Rows[rowIndex].Cells[224].FormattedValue;
                tbpAirJugglersCompliantComment.Text = records.Rows[rowIndex].Cells[225].Value.ToString();
                tbpBallsCompliantChk.Checked = (bool)records.Rows[rowIndex].Cells[226].FormattedValue;
                tbpBallsCompliantComment.Text = records.Rows[rowIndex].Cells[227].Value.ToString();
                tbpGapsChk.Checked = (bool)records.Rows[rowIndex].Cells[228].FormattedValue;
                tbpGapsComment.Text = records.Rows[rowIndex].Cells[229].Value.ToString();
                tbpFittedBaseChk.Checked = (bool)records.Rows[rowIndex].Cells[230].FormattedValue;
                tbpFittedBaseComment.Text = records.Rows[rowIndex].Cells[231].Value.ToString();
                tbpBallPoolDepthValue.Value = (int)records.Rows[rowIndex].Cells[232].Value;
                tbpBallPoolDepthChk.Checked = (bool)records.Rows[rowIndex].Cells[233].FormattedValue;
                tbpBallPoolDepthComment.Text = records.Rows[rowIndex].Cells[234].Value.ToString();
                tbpBallPoolEntryValue.Value = (int)records.Rows[rowIndex].Cells[235].Value;
                tbpBallPoolEntryChk.Checked = (bool)records.Rows[rowIndex].Cells[236].FormattedValue;
                tbpBallPoolEntryComment.Text = records.Rows[rowIndex].Cells[237].Value.ToString();

                //Indoor Only
                indoorOnlyChk.Checked = (bool)records.Rows[rowIndex].Cells[238].FormattedValue;

                //Inflatable Games
                isInflatableGameChk.Checked = (bool)records.Rows[rowIndex].Cells[239].FormattedValue;
                gameTypeComment.Text = records.Rows[rowIndex].Cells[240].Value.ToString();
                gameMaxUserMassChk.Checked = (bool)records.Rows[rowIndex].Cells[241].FormattedValue;
                gameMaxUserMassComment.Text = records.Rows[rowIndex].Cells[242].Value.ToString();
                gameAgeRangeMarkingChk.Checked = (bool)records.Rows[rowIndex].Cells[243].FormattedValue;
                gameAgeRangeMarkingComment.Text = records.Rows[rowIndex].Cells[244].Value.ToString();
                gameConstantAirFlowChk.Checked = (bool)records.Rows[rowIndex].Cells[245].FormattedValue;
                gameConstantAirFlowComment.Text = records.Rows[rowIndex].Cells[246].Value.ToString();
                gameDesignRiskChk.Checked = (bool)records.Rows[rowIndex].Cells[247].FormattedValue;
                gameDesignRiskComment.Text = records.Rows[rowIndex].Cells[248].Value.ToString();
                gameIntendedPlayRiskChk.Checked = (bool)records.Rows[rowIndex].Cells[249].FormattedValue;
                gameIntendedPlayRiskComment.Text = records.Rows[rowIndex].Cells[250].Value.ToString();
                gameAncillaryEquipmentChk.Checked = (bool)records.Rows[rowIndex].Cells[251].FormattedValue;
                gameAncillaryEquipmentComment.Text = records.Rows[rowIndex].Cells[252].Value.ToString();
                gameAncillaryEquipmentCompliantChk.Checked = (bool)records.Rows[rowIndex].Cells[253].FormattedValue;
                gameAncillaryEquipmentCompliantComment.Text = records.Rows[rowIndex].Cells[254].Value.ToString();
                gameContainingWallHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[255].Value;
                gameContainingWallHeightChk.Checked = (bool)records.Rows[rowIndex].Cells[256].FormattedValue;
                gameContainingWallHeightComment.Text = records.Rows[rowIndex].Cells[257].Value.ToString();

                //Catch bed
                isCatchBedChk.Checked = (bool)records.Rows[rowIndex].Cells[258].FormattedValue;
                catchbedTypeOfUnitComment.Text = records.Rows[rowIndex].Cells[259].Value.ToString();
                catchbedMaxUserMassMarkingChk.Checked = (bool)records.Rows[rowIndex].Cells[260].FormattedValue;
                catchbedMaxUserMassMarkingComment.Text = records.Rows[rowIndex].Cells[261].Value.ToString();
                catchbedArrestChk.Checked = (bool)records.Rows[rowIndex].Cells[262].FormattedValue;
                catchbedArrestComment.Text = records.Rows[rowIndex].Cells[263].Value.ToString();
                catchbedMattingChk.Checked = (bool)records.Rows[rowIndex].Cells[264].FormattedValue;
                catchbedMattingComment.Text = records.Rows[rowIndex].Cells[265].Value.ToString();
                catchbedDesignRiskChk.Checked = (bool)records.Rows[rowIndex].Cells[266].FormattedValue;
                catchbedDesignRiskComment.Text = records.Rows[rowIndex].Cells[267].Value.ToString();
                catchbedIntendedPlayChk.Checked = (bool)records.Rows[rowIndex].Cells[268].FormattedValue;
                catchbedIntendedPlayRiskComment.Text = records.Rows[rowIndex].Cells[269].Value.ToString();
                catchbedAncillaryFitChk.Checked = (bool)records.Rows[rowIndex].Cells[270].FormattedValue;
                catchbedAncillaryFitComment.Text = records.Rows[rowIndex].Cells[271].Value.ToString();
                catchbedAncillaryCompliantChk.Checked = (bool)records.Rows[rowIndex].Cells[272].FormattedValue;
                catchbedAncillaryCompliantComment.Text = records.Rows[rowIndex].Cells[273].Value.ToString();
                catchbedApronChk.Checked = (bool)records.Rows[rowIndex].Cells[274].FormattedValue;
                catchbedApronComment.Text = records.Rows[rowIndex].Cells[275].Value.ToString();
                catchbedTroughChk.Checked = (bool)records.Rows[rowIndex].Cells[276].FormattedValue;
                catchbedTroughDepthComment.Text = records.Rows[rowIndex].Cells[277].Value.ToString();
                catchbedFrameworkChk.Checked = (bool)records.Rows[rowIndex].Cells[278].FormattedValue;
                catchbedFrameworkComment.Text = records.Rows[rowIndex].Cells[279].Value.ToString();
                catchbedGroundingChk.Checked = (bool)records.Rows[rowIndex].Cells[280].FormattedValue;
                catchbedGroundingComment.Text = records.Rows[rowIndex].Cells[281].Value.ToString();
                catchbedBedHeightValue.Value = (int)records.Rows[rowIndex].Cells[282].Value;
                catchbedBedHeightChk.Checked = (bool)records.Rows[rowIndex].Cells[283].FormattedValue;
                catchbedBedHeightComment.Text = records.Rows[rowIndex].Cells[284].Value.ToString();
                catchbedPlatformFallDistanceValue.Value = (decimal)records.Rows[rowIndex].Cells[285].Value;
                catchbedPlatformFallDistanceChk.Checked = (bool)records.Rows[rowIndex].Cells[286].FormattedValue;
                catchbedPlatformFallDistanceComment.Text = records.Rows[rowIndex].Cells[287].Value.ToString();
                catchbedBlowerTubeLengthValue.Value = (decimal)records.Rows[rowIndex].Cells[288].Value;
                catchbedBlowerTubeLengthChk.Checked = (bool)records.Rows[rowIndex].Cells[289].FormattedValue;
                catchbedBlowerTubeLengthComment.Text = records.Rows[rowIndex].Cells[290].Value.ToString();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, toolName);
            }

        }

        private void linkLabel1_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            try
            {
                ProcessStartInfo sInfo = new ProcessStartInfo("https://www.patlog.co.uk/");
                sInfo.UseShellExecute = true;
                Process.Start(sInfo);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, toolName);
            }
        }

        private void loadAllRecordsBtn_Click(object sender, EventArgs e)
        {
            loadRecords("SELECT * FROM Inspections;");
        }

        private void clrRecordsBtn_Click(object sender, EventArgs e)
        {
            clearRecords();
        }

        private void searchByOwnerBtn_Click(object sender, EventArgs e)
        {
            if (searchbyUnitOwnerTxt.Text.Length > 0)
            {
                loadRecords("SELECT * FROM Inspections WHERE unitOwner LIKE '" + searchbyUnitOwnerTxt.Text + "%';");
            }
            else
            {
                MessageBox.Show("Enter the partial (or full if known) unit Owner to search.", toolName);
            }
        }

        private void uniqueReportNumberSearchBtn_Click(object sender, EventArgs e)
        {
            if (uniqueReportNumberSearchTxt.Text.Length > 0)
            {
                loadRecords("SELECT * FROM Inspections WHERE TagID = " + uniqueReportNumberSearchTxt.Text + ";");
            }
            else
            {
                MessageBox.Show("Enter the exact Unique Report Number to search.", toolName);
            }
        }

        private void records_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            /*
            They've clicked the "Re-Inspect" button on the records datagridview
            Really, I should have made this the first column - Probably a job for the next update.
            */
            if (e.ColumnIndex == 291)
            {
                /*
                Load that record into the main part of the tool
                This is the part that turns an initial inspection into an annual inspection, because you're loading the historic report!
                */
                loadReportIntoApplication(e.RowIndex);
            }
            else if (e.ColumnIndex == 292)
            {
                /*
                You fucked up and need to delete that record...
                */
                DialogResult dialogResult = MessageBox.Show("Are you sure you want to delete that record?", toolName, MessageBoxButtons.YesNo);
                if (dialogResult == DialogResult.Yes)
                {
                    deleteRowRecord(Int32.Parse(records.Rows[e.RowIndex].Cells[0].Value.ToString()), e.RowIndex);
                }
            }
        }

        private void selectLogoBtn_Click(object sender, EventArgs e)
        {
            chooseLogo();
        }

        private void slideNABtn_Click(object sender, EventArgs e)
        {
            naSlide();
        }
        void naSlide()
        {
            isSlideChk.Checked = false;
            slidePlatformHeightValue.Value = 0;
            slidePlatformHeightComment.Text = "Not Applicable";
            slideWallHeightValue.Value = 0;
            slideWallHeightComment.Text = "Not Applicable";
            slidefirstmetreHeightValue.Value = 0;
            slideFirstMetreHeightComment.Text = "Not Applicable";
            beyondfirstmetreHeightValue.Value = 0;
            beyondfirstmetreHeightComment.Text = "Not Applicable";
            slidePermRoofedCheck.Checked = false;
            slidePermRoofedComment.Text = "Not Applicable";
            clamberNettingPassFail.Checked = false;
            clamberNettingComment.Text = "Not Applicable";
            runoutValue.Value = 0;
            runOutPassFail.Checked = false;
            runoutComment.Text = "Not Applicable";
            slipsheetPassFail.Checked = false;
            slipsheetComment.Text = "Not Applicable";
        }

        private void enclosedNABtn_Click(object sender, EventArgs e)
        {
            naEnclosed();
        }

        void naEnclosed()
        {
            isUnitEnclosedChk.Checked = false;
            exitNumberValue.Value = 0;
            exitNumberPassFail.Checked = false;
            exitNumberComment.Text = "Not Applicable";
            exitsignVisiblePassFail.Checked = false;
            exitSignVisibleComment.Text = "Not Applicable";
        }

        private void passAllStruct1Btn_Click(object sender, EventArgs e)
        {
            seamIntegrityPassFail.Checked = true;
            lockstitchPassFail.Checked = true;
            stitchLengthPassFail.Checked = true;
            airLossPassFail.Checked = true;
            wallStraightPassFail.Checked = true;
            sharpEdgesPassFail.Checked = true;
            tubeDistancePassFail.Checked = true;
            stablePassFail.Checked = true;
            evacTimePassFail.Checked = true;
        }

        private void passAllStruc2Btn_Click(object sender, EventArgs e)
        {
            stepSizePassFail.Checked = true;
            falloffHeightPassFail.Checked = true;
            pressurePassFail.Checked = true;
            troughPassFail.Checked = true;
            entrapPassFail.Checked = true;
            markingsPassFail.Checked = true;
            groundingPassFail.Checked = true;
        }

        private void passAllAnchorBtn_Click(object sender, EventArgs e)
        {
            numAnchorsPassFail.Checked = true;
            anchorAccessoriesPassFail.Checked = true;
            anchorDegreePassFail.Checked = true;
            anchorTypePassFail.Checked = true;
            pullStrengthPassFail.Checked = true;
        }

        private void passAllMaterialsBtn_Click(object sender, EventArgs e)
        {
            ropeSizePassFail.Checked = true;
            clamberPassFail.Checked = true;
            retentionNettingPassFail.Checked = true;
            zipsPassFail.Checked = true;
            windowsPassFail.Checked = true;
            artworkPassFail.Checked = true;
            threadPassFail.Checked = true;
            fabricPassFail.Checked = true;
            fireRetardentPassFail.Checked = true;
        }

        private void passAllBlowerBtn_Click(object sender, EventArgs e)
        {
            blowerFlapPassFail.Checked = true;
            blowerFingerPassFail.Checked = true;
            patPassFail.Checked = true;
            blowerVisualPassFail.Checked = true;
        }

        private void combiBtn_Click(object sender, EventArgs e)
        {
            slidePlatformHeightValue.Value = (decimal)1.50;
            slidePlatformHeightComment.Text = "Slide Combi Applicable - Platform height less than 1.5m and users forced to sit or crouch to enter.";
            slideWallHeightValue.Value = (decimal)1.00;
            slideWallHeightComment.Text = "Slide Combi Applicable - Highest 750 mm of the slope (containing walls) are at least 50 % of user height.";
            slidefirstmetreHeightValue.Value = (decimal)1.00;
            slideFirstMetreHeightComment.Text = "Slide Combi Applicable - Highest 750 mm of the slope (containing walls) are at least 50 % of user height.";
            beyondfirstmetreHeightValue.Value = (decimal)0.50;
            beyondfirstmetreHeightComment.Text = "Slide Combi Applicable - Remainder of the slope at least 300 mm";
            slidePermRoofedCheck.Checked = true;
            slidePermRoofedComment.Text = "Slide Combi Applicable - Yes, user is forced to crouch or sit due to fitted roof.";
            clamberNettingPassFail.Checked = true;
            clamberNettingComment.Text = "Not monofilament, no entrapment and at least 12mm diameter, securely knotted and no fraying, securely fastened.";
            runoutValue.Value = (decimal)0.75;
            runOutPassFail.Checked = true;
            slipsheetPassFail.Checked = true;

        }

        private void slideFirstMetreHeightComment_TextChanged(object sender, EventArgs e)
        {
            slideBarrierHeightComment.Text = slideFirstMetreHeightComment.Text;
        }

        private void beyondfirstmetreHeightComment_TextChanged(object sender, EventArgs e)
        {
            remainingSlideWallHeightComment.Text = beyondfirstmetreHeightComment.Text;
        }

        private void slidePermRoofedComment_TextChanged(object sender, EventArgs e)
        {
            permRoofComment.Text = slidePermRoofedComment.Text;
        }

        private void slideWallHeightComment_TextChanged(object sender, EventArgs e)
        {

        }

        private void AdditionalPic1Btn_Click(object sender, EventArgs e)
        {
            adPhoto1();
        }

        private void AdditionalPic2Btn_Click(object sender, EventArgs e)
        {
            adPhoto2();
        }

        private void AdditionalPic3Btn_Click(object sender, EventArgs e)
        {
            adPhoto3();
        }

        private void AdditionalPic4Btn_Click(object sender, EventArgs e)
        {
            adPhoto4();
        }

        private void newReportBtn_Click(object sender, EventArgs e)
        {
            //Reset
            newReport();
        }

        private void falloffHeight_ValueChanged(object sender, EventArgs e)
        {
            falloffHeightComment.Text = "Critical Fall Off Height is a max of " + falloffHeight.Value.ToString() + "m";
        }

        private void pressureValue_ValueChanged(object sender, EventArgs e)
        {
            pressureComment.Text = "Pressure is a minimum of " + pressureValue.Value.ToString() + " KPA";
        }

        private void deleteAdditionalImage1Btn_Click(object sender, EventArgs e)
        {
            AdditionalPic1.Image = null;
        }

        private void deleteAdditionalImage2Btn_Click(object sender, EventArgs e)
        {
            AdditionalPic2.Image = null;
        }

        private void deleteAdditionalImage3Btn_Click(object sender, EventArgs e)
        {
            AdditionalPic3.Image = null;
        }

        private void deleteAdditionalImage4Btn_Click(object sender, EventArgs e)
        {
            AdditionalPic4.Image = null;
        }

        //This doesn't really sanitise shit - I just remove the appostrophes because that's common when writing a report - Especially in the risk assessment.
        string sanitiseSQL(string input)
        {
            string output = "";
            output = input.Replace("'", "");

            return output;
        }






        private void clearDubegBtn_Click(object sender, EventArgs e)
        {
            debugOutput.Clear();
        }

        private void usersat1000mm_ValueChanged(object sender, EventArgs e)
        {
            if (usersat1000mm.Value > 0)
            {
                if (usersat1200mm.Value == 0 && usersat1500mm.Value == 0 && usersat1800mm.Value == 0)
                {
                    userHeight.Value = (decimal)1.00;
                }
            }
        }

        private void usersat1200mm_ValueChanged(object sender, EventArgs e)
        {
            if (usersat1200mm.Value > 0)
            {
                if (usersat1500mm.Value == 0 && usersat1800mm.Value == 0)
                {
                    userHeight.Value = (decimal)1.20;
                }
            }
        }

        private void usersat1500mm_ValueChanged(object sender, EventArgs e)
        {
            if (usersat1500mm.Value > 0)
            {
                if (usersat1800mm.Value == 0)
                {
                    userHeight.Value = (decimal)1.50;
                }
            }
        }

        private void usersat1800mm_ValueChanged(object sender, EventArgs e)
        {
            if (usersat1800mm.Value > 0)
            {
                userHeight.Value = (decimal)1.80;
            }
        }


        private void bungeeNABtn_Click(object sender, EventArgs e)
        {
            naBungee();
        }

        void naBungee()
        {
            isBungeeRunChk.Checked = false;
            bungeeBlowerDistanceChk.Checked = false;
            bungeeMaxMassChk.Checked = false;
            bungeeMinHeightChk.Checked = false;
            bungeePullTestChk.Checked = false;
            bungeeCordLengthChk.Checked = false;
            bungeeCordDiametreChk.Checked = false;
            bungeeTwoStageChk.Checked = false;
            bungeeBatonCompliantChk.Checked = false;
            bungeeLaneWidthChk.Checked = false;
            bungeeHarnessWidthPassChk.Checked = false;
            bungeeRearWallChk.Checked = false;
            bungeeStartingPosWallChk.Checked = false;
            bungeeRunningWallChk.Checked = false;

            bungeeBlowerDistanceComment.Text = "Non-Applicable";
            bungeeUserMaxMassComment.Text = "Non-Applicable";
            bungeeMinHeightComment.Text = "Non-Applicable";
            bungeeHarnessPullTestComment.Text = "Non-Applicable";
            bungeeCordLengthComment.Text = "Non-Applicable";
            bungeeCordDiametreComment.Text = "Non-Applicable";
            bungeeTwoStageComment.Text = "Non-Applicable";
            bungeeBatonCompliantComment.Text = "Non-Applicable";
            bungeeLaneWidthComment.Text = "Non-Applicable";
            bungeeHarnessWidthComment.Text = "Non-Applicable";
            bungeeRearWallComment.Text = "Non-Applicable";
            bungeeStartingPosWallsComment.Text = "Non-Applicable";
            bungeeRunningWallComment.Text = "Non-Applicable";

            bungeeHarnessWidth.Value = 0;
            bungeeCordAmount.Value = 0;
            bungeeRearWallWidthNum.Value = (decimal)0.0;
            bungeeRearWallHeight.Value = (decimal)0.0;
            bungeeStartingPosWallsLengthNum.Value = (decimal)0.0;
            bungeeStartingPosWallsHeightNum.Value = (decimal)0.0;
            bungeeRunningWallWidthNum.Value = (decimal)0.0;
            bungeeRunningWallHeightNum.Value = (decimal)0.0;
        }

        private void bungeePassAll_Click(object sender, EventArgs e)
        {
            isBungeeRunChk.Checked = true;
            bungeeBlowerDistanceChk.Checked = true;
            bungeeMaxMassChk.Checked = true;
            bungeeMinHeightChk.Checked = true;
            bungeePullTestChk.Checked = true;
            bungeeCordLengthChk.Checked = true;
            bungeeCordDiametreChk.Checked = true;
            bungeeTwoStageChk.Checked = true;
            bungeeBatonCompliantChk.Checked = true;
            bungeeLaneWidthChk.Checked = true;
            bungeeHarnessWidthPassChk.Checked = true;
            bungeeRearWallChk.Checked = true;
            bungeeStartingPosWallChk.Checked = true;
            bungeeRunningWallChk.Checked = true;
        }

        private void fetchPIPABtn_Click(object sender, EventArgs e)
        {
            if (PIPATagNum.Value > 0)
            {
                newReport(); // Best to start a new report here - You don't want to start mixing details from a previous report into here. 
                fetchPIPATagDetails((int)PIPATagNum.Value);
            }
            else
            {
                MessageBox.Show("You need to enter a PIPA tag number to fetch the details.", toolName);
            }
        }


        void fetchPIPATagDetails(int TagNumber)
        {
            try
            {
                var client = new RestClient("https://test-searcher-upm2z.bunny.run/tag/");
                var request = new RestRequest(TagNumber.ToString());

                request.AddHeader("Accept", "application/json");

                RestResponse response = client.ExecuteGet(request);

                //debugOutput.Text = response.Content.ToString();

                Root data = new Root();
                data = JsonSerializer.Deserialize<Root>(response.Content!)!;

                List<AnnualReport> annualReport = data.annualReports;

                //The reports are ordered from newest to oldest, so look at the first report in the array for the latest one!
                Details details = annualReport[1].details; //Does not use zero based indexing, so set this to "1" in the array.

                Device device = details.device;
                Dimensions dimensions = details.dimensions;
                UserLimits userLimits = details.userLimits;
                Structure BedPanelWidth = details.inspectionSections.structure[3];
                Structure TroughDepth = details.inspectionSections.structure[4];
                Structure StitchLength = details.inspectionSections.structure[6];
                Structure InternalWallHeight = details.inspectionSections.structure[7];
                Structure OpenSideFallOffHeight = details.inspectionSections.structure[9];
                Structure Stability = details.inspectionSections.structure[11];
                Structure Entrapment = details.inspectionSections.structure[12];
                Structure SharpAngles = details.inspectionSections.structure[13];
                Structure CeilingNetting = details.inspectionSections.structure[17];
                Structure WallNetting = details.inspectionSections.structure[18];
                Structure ClamberNetting = details.inspectionSections.structure[19];
                Structure Markings = details.inspectionSections.structure[21];
                Structure Artwork = details.inspectionSections.structure[22];
                Anchorage HighAnchors = details.inspectionSections.anchorage[0];
                Anchorage CalculatedAnchors = details.inspectionSections.anchorage[1];
                Anchorage TotalAnchors = details.inspectionSections.anchorage[2];
                Anchorage AnchorAngle = details.inspectionSections.anchorage[3];
                Anchorage AnchorDescription = details.inspectionSections.anchorage[5];
                AreaSurround areaSurround = details.inspectionSections.areaSurround[0];
                Blower blowerDistance = details.inspectionSections.blowers[11];
                EntranceExitsEvacuation EvacutationTime = details.inspectionSections.entranceExitsEvacuation[0];
                EntranceExitsEvacuation Enclosed = details.inspectionSections.entranceExitsEvacuation[1];
                EntranceExitsEvacuation StepPresent = details.inspectionSections.entranceExitsEvacuation[2];
                EntranceExitsEvacuation StepLength = details.inspectionSections.entranceExitsEvacuation[4];
                Slide slidePlatformHeight = details.inspectionSections.slides[1];
                Slide slidePlatformWallHeight = details.inspectionSections.slides[2];
                Slide slideWallHeight = details.inspectionSections.slides[3];
                Slide slideRunOut = details.inspectionSections.slides[5];
                Slide slideRoofFitted = details.inspectionSections.slides[6];
                User customUserHeight = details.inspectionSections.users[4];
                Notes additionalNotes = details.inspectionSections.notes[0];
                Notes riskAssessmentlNotes = details.inspectionSections.notes[1];

                //This outout will get printed to the debugout box at the end - Collecting any errors along the way. 
                string output = "";

                //Make sure you can find the tag number
                if (data.found == true)
                {
                    //If you can find the tag, make sure the details of the latest report are readable and available (they could be the old PDF style). 
                    if (details != null)
                    {
                        //This is where you will actually get all the details and start populating the application.

                        //Set the inflatable description field
                        if (device.name != null)
                        {
                            unitDescriptionText.Text = device.name.ToString();
                        }
                        else
                        {
                            output = "Unit description not retreived.";
                        }
                        //Set the manufacturer field
                        if (device.manufacturer != null)
                        {
                            ManufacturerText.Text = device.manufacturer.ToString();
                        }
                        else
                        {
                            output = "Manufacturer not retreived.";
                        }
                        //Get the unit width dimension and populate as appropriate
                        if (dimensions.width != null)
                        {
                            unitWidthNum.Value = convertStringtoNum(dimensions.width.ToString());
                        }
                        else
                        {
                            output = "Unit Width not retreived.";
                        }
                        //Get the unit length dimension and populate as appropriate
                        if (dimensions.length != null)
                        {
                            unitLengthNum.Value = convertStringtoNum(dimensions.length.ToString());
                        }
                        else
                        {
                            output = "Unit Length not retreived.";
                        }
                        //Get the unit height dimension and populate as appropriate
                        if (dimensions.height != null)
                        {
                            unitHeightNum.Value = convertStringtoNum(dimensions.height.ToString());
                        }
                        else
                        {
                            output = "Unit Height not retreived.";
                        }
                        //Just set the serial number to the PIPA tag number - Not really a problem.
                        serialText.Text = TagNumber.ToString();
                        //Get the slide platform height
                        if (slidePlatformHeight.value != null)
                        {
                            slidePlatformHeightValue.Value = convertStringtoNum(slidePlatformHeight.value.ToString());
                        }
                        else
                        {
                            output = "Slide Platform Height not retreived.";
                        }
                        //Get the slide platform containing wall height
                        if (slidePlatformWallHeight.value != null)
                        {
                            slideWallHeightValue.Value = convertStringtoNum(slidePlatformWallHeight.value.ToString());
                            slidefirstmetreHeightValue.Value = convertStringtoNum(slidePlatformWallHeight.value.ToString()); //PIPA counts this as the same thing.
                        }
                        else
                        {
                            output = "Slide Containing Wall Height not retreived.";
                        }
                        //Get the slide wall height (bit after the first metre)
                        if (slideWallHeight.value != null)
                        {
                            beyondfirstmetreHeightValue.Value = convertStringtoNum(slideWallHeight.value.ToString());
                        }
                        else
                        {
                            output = "Remaining Slide Wall Height (after first metre of slide) not retreived.";
                        }
                        //slide perm roof
                        if (slideRoofFitted.status != null)
                        {
                            slidePermRoofedCheck.Checked = convertStatustoBool(slideRoofFitted.status);
                        }
                        else
                        {
                            slidePermRoofedCheck.Checked = false;//must be false if it cant find it.
                            output = "Perm roof data couldn't be retreived - Set to false automatically.";
                        }
                        //Run Out
                        if (slideRunOut.value != null)//&& slideRunOut.status != null)
                        {
                            runoutValue.Value = convertStringtoNum(slideRunOut.value.ToString());
                            //runOutPassFail.Checked = convertStatustoBool(slideRunOut.status);
                        }
                        else
                        {
                            output = "Slide run-out data not retreived.";
                        }
                        //Containing Wall Height
                        if (InternalWallHeight.value != null)
                        {
                            containingWallHeightValue.Value = convertStringtoNum(InternalWallHeight.value.ToString());
                        }
                        else
                        {
                            output = "Containing wall height data not retreived.";
                        }
                        //Castle platform height
                        if (OpenSideFallOffHeight.value != null)
                        {
                            platformHeightValue.Value = convertStringtoNum(OpenSideFallOffHeight.value.ToString());
                        }
                        else
                        {
                            output = "Tallest Platform height data not retreived.";
                        }
                        //Play Area Length
                        if (areaSurround.value != null)
                        {
                            playAreaLengthComment.Text = "Total play area (considering neg adjustment) Length x Width calculated to " + areaSurround.value.ToString();
                            playAreaWidthComment.Text = "Total play area (considering neg adjustment) Length x Width calculated to " + areaSurround.value.ToString();
                        }
                        else
                        {
                            output = "Play Area Calc data not retreived.";
                        }
                        //User Count 1m
                        if (userLimits.upTo1_0m != null)
                        {
                            usersat1000mm.Value = Int32.Parse(userLimits.upTo1_0m.ToString());
                        }
                        else
                        {
                            output = "User Count @ 1m data not retreived.";
                        }
                        //User Count 1.2m
                        if (userLimits.upTo1_2m != null)
                        {
                            usersat1200mm.Value = Int32.Parse(userLimits.upTo1_2m.ToString());
                        }
                        else
                        {
                            output = "User Count @ 1.2m data not retreived.";
                        }
                        //User Count 1.5m
                        if (userLimits.upTo1_5m != null)
                        {
                            usersat1500mm.Value = Int32.Parse(userLimits.upTo1_5m.ToString());
                        }
                        else
                        {
                            output = "User Count @ 1.5m data not retreived.";
                        }
                        //User Count 1.8m
                        if (userLimits.upTo1_8m != null)
                        {
                            usersat1800mm.Value = Int32.Parse(userLimits.upTo1_8m.ToString());
                        }
                        else
                        {
                            output = "User Count @ 1.8m data not retreived.";
                        }
                        //tubeDistanceValue
                        if (blowerDistance.value != null)
                        {
                            tubeDistanceValue.Value = convertStringtoNum(blowerDistance.value.ToString());
                        }
                        else
                        {
                            output = "Tube Distance data not retreived.";
                        }
                        //Evacutation Time
                        if (EvacutationTime.value != null)
                        {
                            evacTime.Value = convertStringtoNum(EvacutationTime.value.ToString());
                        }
                        else
                        {
                            output = "Evacutation Time data not retreived.";
                        }
                        //step size
                        if (StepLength.value != null)
                        {
                            stepSizeValue.Value = convertStringtoNum(StepLength.value.ToString());
                        }
                        else
                        {
                            output = "Step Length data not retreived.";
                        }
                        //Critical fall off Height
                        if (OpenSideFallOffHeight.value != null)
                        {
                            falloffHeight.Value = convertStringtoNum(OpenSideFallOffHeight.value.ToString());
                        }
                        else
                        {
                            output = "Critical Fall-Off height data not retreived.";
                        }
                        //troughDepthValue
                        if (TroughDepth.value != null)
                        {
                            troughDepthValue.Value = 1000 * (convertStringtoNum(TroughDepth.value.ToString()));
                        }
                        else
                        {
                            output = "trough depth data not retreived.";
                        }
                        //Bed Panel Width - adjacent panel
                        if (BedPanelWidth.value != null)
                        {
                            troughWidthValue.Value = 1000 * (convertStringtoNum(BedPanelWidth.value.ToString()));
                        }
                        else
                        {
                            output = "Adjacent panel width data not retreived.";
                        }
                        //Anchors
                        if (TotalAnchors.value != null && HighAnchors.value != null) //PIPA doesn't record low anchors - It records high anchorsd and total anchors. How annoying.
                        {
                            numLowAnchors.Value = (Int32.Parse(TotalAnchors.value) - Int32.Parse(HighAnchors.value));
                            numHighAnchors.Value = convertStringtoNum(HighAnchors.value.ToString());
                        }
                        else
                        {
                            output = "Anchor point data not retreived.";
                        }

                        //Now just set all the checkboxes to pass (only the ones that are about passing, not the fitted roof ones and indicating features.). 
                        //Obviously the inspector needs to check that's correct - But it saves clicking time.

                        clamberNettingPassFail.Checked = true;
                        runOutPassFail.Checked = true;
                        slipsheetPassFail.Checked = true;
                        seamIntegrityPassFail.Checked = true;
                        lockstitchPassFail.Checked = true;
                        stitchLengthPassFail.Checked = true;
                        airLossPassFail.Checked = true;
                        wallStraightPassFail.Checked = true;
                        sharpEdgesPassFail.Checked = true;
                        tubeDistancePassFail.Checked = true;
                        stablePassFail.Checked = true;
                        evacTimePassFail.Checked = true;
                        stepSizePassFail.Checked = true;
                        falloffHeightPassFail.Checked = true;
                        pressurePassFail.Checked = true;
                        troughPassFail.Checked = true;
                        entrapPassFail.Checked = true;
                        markingsPassFail.Checked = true;
                        groundingPassFail.Checked = true;
                        numAnchorsPassFail.Checked = true;
                        anchorAccessoriesPassFail.Checked = true;
                        anchorDegreePassFail.Checked = true;
                        anchorTypePassFail.Checked = true;
                        pullStrengthPassFail.Checked = true;
                        ropeSizePassFail.Checked = true;
                        clamberPassFail.Checked = true;
                        retentionNettingPassFail.Checked = true;
                        zipsPassFail.Checked = true;
                        windowsPassFail.Checked = true;
                        artworkPassFail.Checked = true;
                        threadPassFail.Checked = true;
                        fabricPassFail.Checked = true;
                        fireRetardentPassFail.Checked = true;
                        blowerFlapPassFail.Checked = true;
                        blowerFingerPassFail.Checked = true;
                        patPassFail.Checked = true;
                        blowerVisualPassFail.Checked = true;

                    }
                    else
                    {
                        output = output + TagNumber.ToString() + " was found, but the report is the old style PDF or some other weird error meaning we can't get the details. Darn!\n";
                    }
                }
                else
                {
                    output = output + TagNumber.ToString() + " Not found!\n";
                }
                debugOutput.Text = debugOutput.Text + "\n" + output;
                debugOutput.Text = debugOutput.Text + "\n" + "Completed.";
            }
            catch (Exception ex)
            {
                debugOutput.Text = ex.Message;
            }
        }



        decimal convertStringtoNum(string value)
        {
            decimal result = 0;
            try
            {
                string newString = Regex.Replace(value, "[^.0-9]", "");
                result = decimal.Parse(newString);
            }
            catch
            {

            }
            return result;
        }

        bool convertStatustoBool(string status)
        {
            bool result = false;
            if (status == "Pass")
            {
                result = true;
            }
            else
            {
                result = false;
            }
            return result;
        }

        private void playzoneNABtn_Click(object sender, EventArgs e)
        {
            naPlayZone();
        }

        void naPlayZone()
        {
            playZoneAgeMarkingComment.Text = "Non-Applicable";
            playZoneHeightMarkingComment.Text = "Non-Applicable";
            playZoneSightLineComment.Text = "Non-Applicable";
            playZoneAccessComment.Text = "Non-Applicable";
            playZoneSuitableMattingComment.Text = "Non-Applicable";
            playZoneTrafficFlowComment.Text = "Non-Applicable";
            playZoneAirJugglerComment.Text = "Non-Applicable";
            playZoneBallsComment.Text = "Non-Applicable";
            playZoneBallPoolGapsComment.Text = "Non-Applicable";
            playZoneFittedSheetComment.Text = "Non-Applicable";
            playZoneBallPoolDepthComment.Text = "Non-Applicable";
            playZoneBallPoolEntryHeightComment.Text = "Non-Applicable";
            playZoneSlideGradComment.Text = "Non-Applicable";
            playZoneSlidePlatHeightComment.Text = "Non-Applicable";

            playZoneIsPlayZoneChk.Checked = false;
            playZoneAgeMarkingChk.Checked = false;
            playZoneHeightMarkingChk.Checked = false;
            playZoneSightLineChk.Checked = false;
            playZoneAccessChk.Checked = false;
            playZoneSuitableMattingChk.Checked = false;
            playZoneTrafficChk.Checked = false;
            playZoneAirJugglerChk.Checked = false;
            playZoneBallsChk.Checked = false;
            playZoneBallPoolGapsChk.Checked = false;
            playZoneFittedSheetChk.Checked = false;
            playZoneBallPoolDepthChk.Checked = false;
            playZoneBallPoolEntryHeightChk.Checked = false;
            playZoneSlideGradChk.Checked = false;
            playZoneSlidePlatHeightChk.Checked = false;

            playZoneBallPoolDepthValue.Value = 0;
            playZoneBallPoolEntryHeightValue.Value = 0;
            playZoneSlideGradValue.Value = 0;
            playZoneSlidePlatHeightValue.Value = 0;
        }

        private void playZonePassAllBtn_Click(object sender, EventArgs e)
        {
            playZoneIsPlayZoneChk.Checked = true;
            playZoneAgeMarkingChk.Checked = true;
            playZoneHeightMarkingChk.Checked = true;
            playZoneSightLineChk.Checked = true;
            playZoneAccessChk.Checked = true;
            playZoneSuitableMattingChk.Checked = true;
            playZoneTrafficChk.Checked = true;
            playZoneAirJugglerChk.Checked = true;
            playZoneBallsChk.Checked = true;
            playZoneBallPoolGapsChk.Checked = true;
            playZoneFittedSheetChk.Checked = true;
            playZoneBallPoolDepthChk.Checked = true;
            playZoneBallPoolEntryHeightChk.Checked = true;
            playZoneSlideGradChk.Checked = true;
            playZoneSlidePlatHeightChk.Checked = true;
        }

        private void tbpNABtn_Click(object sender, EventArgs e)
        {
            naBallPool();
        }

        void naBallPool()
        {
            isToddlerBallPoolChk.Checked = false;
            tbpAgeRangeMarkingChk.Checked = false;
            tblMaxHeightMarkingsChk.Checked = false;
            tbpSuitableMattingChk.Checked = false;
            tbpAirJugglersCompliantChk.Checked = false;
            tbpBallsCompliantChk.Checked = false;
            tbpGapsChk.Checked = false;
            tbpFittedBaseChk.Checked = false;
            tbpBallPoolDepthChk.Checked = false;
            tbpBallPoolEntryChk.Checked = false;

            tbpBallPoolDepthValue.Value = 0;
            tbpBallPoolEntryValue.Value = 0;

            tbpAgeRangeMarkingComment.Text = "Non-Applicable";
            tpbMaxHeightMarkingsComment.Text = "Non-Applicable";
            tbpSuitableMattingComment.Text = "Non-Applicable";
            tbpAirJugglersCompliantComment.Text = "Non-Applicable";
            tbpBallsCompliantComment.Text = "Non-Applicable";
            tbpGapsComment.Text = "Non-Applicable";
            tbpFittedBaseComment.Text = "Non-Applicable";
            tbpBallPoolDepthComment.Text = "Non-Applicable";
            tbpBallPoolEntryComment.Text = "Non-Applicable";
        }

        private void tbpPassAllBtn_Click(object sender, EventArgs e)
        {
            isToddlerBallPoolChk.Checked = true;
            tbpAgeRangeMarkingChk.Checked = true;
            tblMaxHeightMarkingsChk.Checked = true;
            tbpSuitableMattingChk.Checked = true;
            tbpAirJugglersCompliantChk.Checked = true;
            tbpBallsCompliantChk.Checked = true;
            tbpGapsChk.Checked = true;
            tbpFittedBaseChk.Checked = true;
            tbpBallPoolDepthChk.Checked = true;
            tbpBallPoolEntryChk.Checked = true;
        }

        private void gameNonApplicableBtn_Click(object sender, EventArgs e)
        {
            naInflatableGame();
        }

        void naInflatableGame()
        {
            isInflatableGameChk.Checked = false;
            gameMaxUserMassChk.Checked = false;
            gameAgeRangeMarkingChk.Checked = false;
            gameConstantAirFlowChk.Checked = false;
            gameDesignRiskChk.Checked = false;
            gameIntendedPlayRiskChk.Checked = false;
            gameAncillaryEquipmentChk.Checked = false;
            gameAncillaryEquipmentCompliantChk.Checked = false;
            gameContainingWallHeightChk.Checked = false;

            gameContainingWallHeightValue.Value = 0;

            gameTypeComment.Text = "Non-Applicable";
            gameMaxUserMassComment.Text = "Non-Applicable";
            gameAgeRangeMarkingComment.Text = "Non-Applicable";
            gameConstantAirFlowComment.Text = "Non-Applicable";
            gameDesignRiskComment.Text = "Non-Applicable";
            gameIntendedPlayRiskComment.Text = "Non-Applicable";
            gameAncillaryEquipmentComment.Text = "Non-Applicable";
            gameAncillaryEquipmentCompliantComment.Text = "Non-Applicable";
            gameContainingWallHeightComment.Text = "Non-Applicable";
        }

        private void gamePassAllBtn_Click(object sender, EventArgs e)
        {
            isInflatableGameChk.Checked = true;
            gameMaxUserMassChk.Checked = true;
            gameAgeRangeMarkingChk.Checked = true;
            gameConstantAirFlowChk.Checked = true;
            gameDesignRiskChk.Checked = true;
            gameIntendedPlayRiskChk.Checked = true;
            gameAncillaryEquipmentChk.Checked = true;
            gameAncillaryEquipmentCompliantChk.Checked = true;
            gameContainingWallHeightChk.Checked = true;
        }


        private void Form1_Load(object sender, EventArgs e)
        {
            inspectionTabControl.TabPages.Remove(BungeeTab);
            inspectionTabControl.TabPages.Remove(Bungee2Tab);
            inspectionTabControl.TabPages.Remove(PlayZoneTab);
            inspectionTabControl.TabPages.Remove(PlayZoneTabCont);
            inspectionTabControl.TabPages.Remove(BallPoolTab);
            inspectionTabControl.TabPages.Remove(inflatableGameTab);
            inspectionTabControl.TabPages.Remove(SlideTab);
            inspectionTabControl.TabPages.Remove(EnclosedTab);
            inspectionTabControl.TabPages.Remove(catchbedTab);
            inspectionTabControl.TabPages.Remove(catchbedContTab);
        }

        private void sectionsCheckList_ItemCheck(object sender, ItemCheckEventArgs e)
        {
            if (e.Index == 0) //Slide
            {
                if (sectionsCheckList.GetItemChecked(0) == false)
                {
                    inspectionTabControl.TabPages.Insert(1, SlideTab);
                }
                else
                {
                    inspectionTabControl.TabPages.Remove(SlideTab);
                }
            }
            else if (e.Index == 1) //Bungee run
            {
                if (sectionsCheckList.GetItemChecked(1) == false)
                {
                    inspectionTabControl.TabPages.Insert(1, BungeeTab);
                    inspectionTabControl.TabPages.Insert(2, Bungee2Tab);
                }
                else
                {
                    inspectionTabControl.TabPages.Remove(BungeeTab);
                    inspectionTabControl.TabPages.Remove(Bungee2Tab);
                }
            }
            else if (e.Index == 2) //Play zone
            {
                if (sectionsCheckList.GetItemChecked(2) == false)
                {
                    inspectionTabControl.TabPages.Insert(1, PlayZoneTab);
                    inspectionTabControl.TabPages.Insert(2, PlayZoneTabCont);
                }
                else
                {
                    inspectionTabControl.TabPages.Remove(PlayZoneTab);
                    inspectionTabControl.TabPages.Remove(PlayZoneTabCont);
                }
            }
            else if (e.Index == 3) //Ball pool
            {
                if (sectionsCheckList.GetItemChecked(3) == false)
                {
                    inspectionTabControl.TabPages.Insert(1, BallPoolTab);
                }
                else
                {
                    inspectionTabControl.TabPages.Remove(BallPoolTab);
                }
            }
            else if (e.Index == 4) //Inflatable game
            {
                if (sectionsCheckList.GetItemChecked(4) == false)
                {
                    inspectionTabControl.TabPages.Insert(1, inflatableGameTab);
                }
                else
                {
                    inspectionTabControl.TabPages.Remove(inflatableGameTab);
                }
            }
            else if (e.Index == 5) //Enclosed unit
            {
                if (sectionsCheckList.GetItemChecked(5) == false)
                {
                    inspectionTabControl.TabPages.Insert(1, EnclosedTab);
                }
                else
                {
                    inspectionTabControl.TabPages.Remove(EnclosedTab);
                }
            }
            else if (e.Index == 6) //Catch Bed
            {
                if (sectionsCheckList.GetItemChecked(6) == false)
                {
                    inspectionTabControl.TabPages.Insert(1, catchbedTab);
                    inspectionTabControl.TabPages.Insert(2, catchbedContTab);
                }
                else
                {
                    inspectionTabControl.TabPages.Remove(catchbedTab);
                    inspectionTabControl.TabPages.Remove(catchbedContTab);
                }
            }
        }

        private void catchbedNABtn_Click(object sender, EventArgs e)
        {
            naCatchBed();
        }

        void naCatchBed()
        {
            isCatchBedChk.Checked = false;
            catchbedMaxUserMassMarkingChk.Checked = false;
            catchbedArrestChk.Checked = false;
            catchbedMattingChk.Checked = false;
            catchbedDesignRiskChk.Checked = false;
            catchbedIntendedPlayChk.Checked = false;
            catchbedAncillaryFitChk.Checked = false;
            catchbedAncillaryCompliantChk.Checked = false;
            catchbedApronChk.Checked = false;
            catchbedTroughChk.Checked = false;
            catchbedFrameworkChk.Checked = false;
            catchbedGroundingChk.Checked = false;
            catchbedBedHeightChk.Checked = false;
            catchbedPlatformFallDistanceChk.Checked = false;
            catchbedBlowerTubeLengthChk.Checked = false;

            catchbedTypeOfUnitComment.Text = "Non-Applicable";
            catchbedMaxUserMassMarkingComment.Text = "Non-Applicable";
            catchbedArrestComment.Text = "Non-Applicable";
            catchbedMattingComment.Text = "Non-Applicable";
            catchbedDesignRiskComment.Text = "Non-Applicable";
            catchbedIntendedPlayRiskComment.Text = "Non-Applicable";
            catchbedAncillaryFitComment.Text = "Non-Applicable";
            catchbedAncillaryCompliantComment.Text = "Non-Applicable";
            catchbedApronComment.Text = "Non-Applicable";
            catchbedTroughDepthComment.Text = "Non-Applicable";
            catchbedFrameworkComment.Text = "Non-Applicable";
            catchbedGroundingComment.Text = "Non-Applicable";
            catchbedBedHeightComment.Text = "Non-Applicable";
            catchbedPlatformFallDistanceComment.Text = "Non-Applicable";
            catchbedBlowerTubeLengthComment.Text = "Non-Applicable";

            catchbedBedHeightValue.Value = 0;
            catchbedPlatformFallDistanceValue.Value = (decimal)0.00;
            catchbedBlowerTubeLengthValue.Value = (decimal)0.00;
        }

        private void catchbedPassAllBtn_Click(object sender, EventArgs e)
        {
            isCatchBedChk.Checked = true;
            catchbedMaxUserMassMarkingChk.Checked = true;
            catchbedArrestChk.Checked = true;
            catchbedMattingChk.Checked = true;
            catchbedDesignRiskChk.Checked = true;
            catchbedIntendedPlayChk.Checked = true;
            catchbedAncillaryFitChk.Checked = true;
            catchbedAncillaryCompliantChk.Checked = true;
            catchbedApronChk.Checked = true;
            catchbedTroughChk.Checked = true;
            catchbedFrameworkChk.Checked = false; //Stays as false always.
            catchbedGroundingChk.Checked = true;
            catchbedBedHeightChk.Checked = true;
            catchbedPlatformFallDistanceChk.Checked = true;
            catchbedBlowerTubeLengthChk.Checked = true;
        }

        private void isUnitEnclosedChk_CheckedChanged(object sender, EventArgs e)
        {
            if (isUnitEnclosedChk.Checked == true)
            {
                sectionsCheckList.SetItemChecked(5, true);
            }
        }

        private void isSlideChk_CheckedChanged(object sender, EventArgs e)
        {
            if (isSlideChk.Checked == true)
            {
                sectionsCheckList.SetItemChecked(0, true);
            }
        }

        private void isCatchBedChk_CheckedChanged(object sender, EventArgs e)
        {
            if (isCatchBedChk.Checked == true)
            {
                sectionsCheckList.SetItemChecked(6, true);
            }
        }

        private void isInflatableGameChk_CheckedChanged(object sender, EventArgs e)
        {
            if (isInflatableGameChk.Checked == true)
            {
                sectionsCheckList.SetItemChecked(4, true);
            }
        }

        private void isToddlerBallPoolChk_CheckedChanged(object sender, EventArgs e)
        {
            if (isToddlerBallPoolChk.Checked == true)
            {
                sectionsCheckList.SetItemChecked(3, true);
            }
        }

        private void playZoneIsPlayZoneChk_CheckedChanged(object sender, EventArgs e)
        {
            if (playZoneIsPlayZoneChk.Checked == true)
            {
                sectionsCheckList.SetItemChecked(2, true);
            }
        }

        private void isBungeeRunChk_CheckedChanged(object sender, EventArgs e)
        {
            if (isBungeeRunChk.Checked == true)
            {
                sectionsCheckList.SetItemChecked(1, true);
            }
        }
    }
}
