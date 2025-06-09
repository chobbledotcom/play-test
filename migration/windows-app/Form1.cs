using PdfSharp.Drawing;
using PdfSharp.Drawing.Layout;
using PdfSharp.Fonts;
using PdfSharp.Pdf;
using PdfSharp.UniversalAccessibility.Drawing;
using System.Data;
using System.Data.Entity;
using System.Data.SQLite;
using System.Diagnostics;
using System.Diagnostics.PerformanceData;
using System.Security.Policy;
using System.Windows.Forms;
//using static System.Net.Mime.MediaTypeNames;

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
                    "image TEXT," +

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
                    "Testimony TEXT" +
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

            string inspectionCompany = InspectionCompName.Text;
            string inspectionDate = datePicker.Value.ToLongDateString();
            string RPIIRegNum = rpiiReg.Text;
            string placeInspected = inspectionLocation.Text;
            string unitDescription = unitDescriptionText.Text;
            string unitManufacturer = ManufacturerText.Text;
            string unitWidth = unitWidthNum.Value.ToString();
            string unitLength = unitLengthNum.Value.ToString();
            string unitHeight = unitHeightNum.Value.ToString();
            string serial = serialText.Text;
            string unitType = unitTypeText.Text;
            string unitOwner = unitOwnerText.Text;
            string image = ConvertImageToString(compressImage(unitPic.Image, (double)400, (double)400));
            string containingWallHeight = containingWallHeightValue.Value.ToString();
            string containingWallHeightCommentText = containingWallHeightComment.Text;
            string platformHeight = platformHeightValue.Value.ToString();
            string platformHeightCommentText = platformHeightComment.Text;
            string slideBarrierHeight = slidebarrierHeightValue.Value.ToString();
            string slideBarrierHeightCommentText = slideBarrierHeightComment.Text;
            string remainingSlideWallHeight = remainingSlideWallHeightValue.Value.ToString();
            string remainingSlideWallHeightCommentText = remainingSlideWallHeightComment.Text;
            string permanentRoof = permanentRoofChecked.Checked.ToString();
            string permanentRoofCommentText = permRoofComment.Text;
            string userHeightValue = userHeight.Value.ToString();
            string userHeightCommentText = userHeightComment.Text;
            string playAreaLength = playAreaLengthValue.Value.ToString();
            string playAreaLengthCommentText = playAreaLengthComment.Text;
            string playAreaWidth = playAreaWidthValue.Value.ToString();
            string playAreaWidthCommentText = playAreaWidthComment.Text;
            string playAreaNegAdj = negAdjustmentValue.Value.ToString();
            string playAreaNedAdjCommentText = negAdjustmentComment.Text;
            string numUsersat1000mm = usersat1000mm.Value.ToString();
            string numUsersat1200mm = usersat1200mm.Value.ToString();
            string numUsersat1500mm = usersat1500mm.Value.ToString();
            string numUsersat1800mm = usersat1800mm.Value.ToString();
            string slidePlatformHeight = slidePlatformHeightValue.Value.ToString();
            string slidePlatformHeightCommentText = slidePlatformHeightComment.Text;
            string slideWallHeight = slideWallHeightValue.Value.ToString();
            string slideWallHeightCommentText = slideWallHeightComment.Text;
            string slideFirstMetreHeight = slidefirstmetreHeightValue.Value.ToString();
            string slideFirstMetreHeightCommentText = slideFirstMetreHeightComment.Text;
            string slideBeyondFirstMetreHeight = beyondfirstmetreHeightValue.Value.ToString();
            string beyondfirstmetreHeightCommentText = beyondfirstmetreHeightComment.Text;
            string slidePermRoof = slidePermRoofedCheck.Checked.ToString();
            string slidePermRoofCommentText = slidePermRoofedComment.Text;
            string clamberNettingPass = clamberNettingPassFail.Checked.ToString();
            string clamberNettingCommentText = clamberNettingComment.Text;
            string runout = runoutValue.Value.ToString();
            string runoutPass = runOutPassFail.Checked.ToString();
            string runoutCommentText = runoutComment.Text;
            string slipsheetPass = slipsheetPassFail.Checked.ToString();
            string slipsheetCommentText = slipsheetComment.Text;
            string seamIntegrityPass = seamIntegrityPassFail.Checked.ToString();
            string seamIntegrityCommentText = seamIntegrityComment.Text;
            string lockStitchPass = lockstitchPassFail.Checked.ToString();
            string lockStitchCommentText = lockStitchComment.Text;
            string stitchLength = stitchLengthValue.Value.ToString();
            string stitchLengthPass = stitchLengthPassFail.Checked.ToString();
            string stitchLengthCommentText = stitchLengthComment.Text;
            string airLoss = airLossPassFail.Checked.ToString();
            string airLossCommentText = airLossComment.Text;
            string straightWalls = wallStraightPassFail.Checked.ToString();
            string straightWallsComment = wallStraightComment.Text;
            string sharpEdgesPass = sharpEdgesPassFail.Checked.ToString();
            string sharpEdgesCommentText = sharpEdgesComment.Text;
            string blowerTubeLengthValue = tubeDistanceValue.Value.ToString();
            string blowerTubeLengthPass = tubeDistancePassFail.Checked.ToString();
            string blowerTubeLengthCommentText = tubeDistanceComment.Text;
            string unitStablePass = stablePassFail.Checked.ToString();
            string unitStableComment = stableComment.Text;
            string evacTimeValue = evacTime.Value.ToString();
            string evacTimePass = evacTimePassFail.Checked.ToString();
            string evacTimeCommentText = evacTimeComment.Text;
            string stepSize = stepSizeValue.Value.ToString();
            string stepSizePass = stepSizePassFail.Checked.ToString();
            string stepSizeCommentText = stepSizeComment.Text;
            string falloffHeightValue = falloffHeight.Value.ToString();
            string falloffHeightPass = falloffHeightPassFail.Checked.ToString();
            string falloffHeightCommentText = falloffHeightComment.Text;
            string pressureVal = pressureValue.Value.ToString();
            string pressurePass = pressurePassFail.Checked.ToString();
            string pressureCommentText = pressureComment.Text;
            string troughDepth = troughDepthValue.Value.ToString();
            string troughWidth = troughWidthValue.Value.ToString();
            string troughPass = troughPassFail.Checked.ToString();
            string troughDepthComment = troughComment.Text;
            string entrapPass = entrapPassFail.Checked.ToString();
            string entrapPassComment = entrapComment.Text;
            string markings = markingsPassFail.Checked.ToString();
            string markingCommentText = markingsComment.Text;
            string groundingPass = groundingPassFail.Checked.ToString();
            string groundingCommentText = groundingComment.Text;
            string numLowAnchorsValue = numLowAnchors.Value.ToString();
            string numHighAnchorsValue = numHighAnchors.Value.ToString();
            string numAnchorsPass = numAnchorsPassFail.Checked.ToString();
            string numAnchorsCommentText = numAnchorsComment.Text;
            string anchorAccessoriesPass = anchorAccessoriesPassFail.Checked.ToString();
            string anchorAccessoriesCommentText = AnchorAccessoriesComment.Text;
            string anchorDegreesPass = anchorDegreePassFail.Checked.ToString();
            string anchorDegreesCommentText = anchorDegreesComment.Text;
            string anchorTypePass = anchorTypePassFail.Checked.ToString();
            string anchorTypeCommentText = anchorTypeComment.Text;
            string pullStrengthPass = pullStrengthPassFail.Checked.ToString();
            string pullStrengthCommentText = pullStrengthComment.Text;
            string exitNumber = exitNumberValue.Value.ToString();
            string exitNumberPass = exitNumberPassFail.Checked.ToString();
            string exitNumberCommentText = exitNumberComment.Text;
            string exitVisiblePass = exitsignVisiblePassFail.Checked.ToString();
            string exitVisibleCommentText = exitSignVisibleComment.Text;
            string ropeSize = ropesizeValue.Value.ToString();
            string ropeSizePass = ropeSizePassFail.Checked.ToString();
            string ropeSizeCommentText = ropeSizeComment.Text;
            string clamberPass = clamberPassFail.Checked.ToString();
            string clamberCommentText = clamberComment.Text;
            string retentionNettingPass = retentionNettingPassFail.Checked.ToString();
            string retentionNettingCommentText = retentionNettingComment.Text;
            string zipsPass = zipsPassFail.Checked.ToString();
            string zipsCommentText = zipsComment.Text;
            string windowsPass = windowsPassFail.Checked.ToString();
            string windowsCommentText = windowsComment.Text;
            string artworkPass = artworkPassFail.Checked.ToString();
            string artworkCommentText = artworkComment.Text;
            string threadPass = threadPassFail.Checked.ToString();
            string threadCommentText = threadComment.Text;
            string fabricPass = fabricPassFail.Checked.ToString();
            string fabricCommentText = fabricComment.Text;
            string fireRetardentPass = fireRetardentPassFail.Checked.ToString();
            string fireRetardentCommentText = fireRetardentComment.Text;
            string fanSizeCommentText = blowerSizeComment.Text;
            string blowerFlapPass = blowerFlapPassFail.Checked.ToString();
            string blowerFlapCommentText = blowerFlapComment.Text;
            string blowerFingerPass = blowerFingerPassFail.Checked.ToString();
            string blowerFingerCommentText = blowerFingerComment.Text;
            string patPass = patPassFail.Checked.ToString();
            string patCommentText = patComment.Text;
            string blowerVisualPass = blowerVisualPassFail.Checked.ToString();
            string blowerVisualCommentText = blowerVisualComment.Text;
            string blowerSerialText = blowerSerial.Text;
            string riskAssessment = riskAssessmentNotes.Text;
            string passed = passedRadio.Checked.ToString();
            string testimonyText = testimony.Text;

            sqlite_cmd.CommandText =
                "INSERT INTO Inspections(" +
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
                "image," +
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
                "Testimony" +
                ") " +
                "VALUES(" +
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
                "'" + image + "'," +
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
                "'" + testimonyText + "'" +
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
            saveInspection();
        }

        private void newBtn_Click(object sender, EventArgs e)
        {

        }

        private void createPDFBtn_Click(object sender, EventArgs e)
        {
            createPDFCert();
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one. 

        private void platformHeightValue_ValueChanged(object sender, EventArgs e)
        {
            slidePlatformHeightValue.Value = platformHeightValue.Value;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one. 

        private void slidePlatformHeightValue_ValueChanged(object sender, EventArgs e)
        {
            platformHeightValue.Value = slidePlatformHeightValue.Value;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one. 

        private void slideWallHeightValue_ValueChanged(object sender, EventArgs e)
        {
            containingWallHeightValue.Value = slideWallHeightValue.Value;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one. 

        private void containingWallHeightValue_ValueChanged(object sender, EventArgs e)
        {
            slideWallHeightValue.Value = containingWallHeightValue.Value;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one. 

        private void slidefirstmetreHeightValue_ValueChanged(object sender, EventArgs e)
        {
            slidebarrierHeightValue.Value = slidefirstmetreHeightValue.Value;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one. 

        private void slidebarrierHeightValue_ValueChanged(object sender, EventArgs e)
        {
            slidefirstmetreHeightValue.Value = slidebarrierHeightValue.Value;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one. 

        private void remainingSlideWallHeightValue_ValueChanged(object sender, EventArgs e)
        {
            beyondfirstmetreHeightValue.Value = remainingSlideWallHeightValue.Value;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one. 

        private void beyondfirstmetreHeightValue_ValueChanged(object sender, EventArgs e)
        {
            remainingSlideWallHeightValue.Value = beyondfirstmetreHeightValue.Value;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one.

        private void slidePermRoofedCheck_CheckedChanged(object sender, EventArgs e)
        {
            permanentRoofChecked.Checked = slidePermRoofedCheck.Checked;
        }

        //This is just to avoid some duplication of effort. When you enter the details on one of the tabs it mirrors over to the other one.

        private void permanentRoofChecked_CheckedChanged(object sender, EventArgs e)
        {
            slidePermRoofedCheck.Checked = permanentRoofChecked.Checked;
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
        Carefully formatted to make it eaiser to debug and read. 
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
                        sqlite_datareader.GetString(1), // Inspection Company
                        sqlite_datareader.GetString(2), // inspection Date
                        sqlite_datareader.GetString(3), // RPII Reg Number
                        sqlite_datareader.GetString(4), // Place Inspected
                        sqlite_datareader.GetString(5), // Unit Description
                        sqlite_datareader.GetString(6), //Unit Manufacturer
                        sqlite_datareader.GetDecimal(7), // Unit Width
                        sqlite_datareader.GetDecimal(8), // Unit Length
                        sqlite_datareader.GetDecimal(9), // Unit Height   
                        sqlite_datareader.GetString(10).ToString(), // Serial
                        sqlite_datareader.GetString(11).ToString(), // Unit Type
                        sqlite_datareader.GetString(12).ToString(), // Unit Owner
                        ConvertStringToImage(sqlite_datareader.GetString(13)), // Unit Image
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
                        sqlite_datareader.GetDecimal(36), // Slide platform height
                        sqlite_datareader.GetString(37), // slide platform height Comment
                        sqlite_datareader.GetDecimal(38), // slide wall height
                        sqlite_datareader.GetString(39), // slide wall height Comment
                        sqlite_datareader.GetDecimal(40), // slide first metre height
                        sqlite_datareader.GetString(41), // slide first metre height Comment
                        sqlite_datareader.GetDecimal(42), // slide beyond first metre height
                        sqlite_datareader.GetString(43), // slide beyond first metre height Comment
                        sqlite_datareader.GetString(44), // slide perm roof
                        sqlite_datareader.GetString(45), // slide perm roof comment
                        sqlite_datareader.GetString(46), // clamber netting pass
                        sqlite_datareader.GetString(47), // clamber metting comment
                        sqlite_datareader.GetDecimal(48), // run out value
                        sqlite_datareader.GetString(49), // run out pass
                        sqlite_datareader.GetString(50), // run out comment
                        sqlite_datareader.GetString(51), // slip sheet pass
                        sqlite_datareader.GetString(52), // slip sheet comment
                        sqlite_datareader.GetString(53), // seam integrity pass
                        sqlite_datareader.GetString(54), // seam integrity comment
                        sqlite_datareader.GetString(55), // lock stitch pass
                        sqlite_datareader.GetString(56), // lock stitch comment
                        sqlite_datareader.GetInt32(57), // stitch length value
                        sqlite_datareader.GetString(58), // stitch length pass
                        sqlite_datareader.GetString(59), // stitch length comment
                        sqlite_datareader.GetString(60), // Air loss pass
                        sqlite_datareader.GetString(61), // Air loss comment
                        sqlite_datareader.GetString(62), // Straight walls pass
                        sqlite_datareader.GetString(63), // Straight walls comment
                        sqlite_datareader.GetString(64), // Sharp Edges pass
                        sqlite_datareader.GetString(65), // Sharp edges comment
                        sqlite_datareader.GetDecimal(66), // blower tube length
                        sqlite_datareader.GetString(67), // blower tube pass
                        sqlite_datareader.GetString(68), // blower tube comment
                        sqlite_datareader.GetString(69), // unit stable
                        sqlite_datareader.GetString(70), // unit stable comment
                        sqlite_datareader.GetInt32(71), // Evauation Time
                        sqlite_datareader.GetString(72), // Evacuation Time Pass
                        sqlite_datareader.GetString(73), // Evacuation time comment
                        sqlite_datareader.GetDecimal(74), // step size value
                        sqlite_datareader.GetString(75), // step size pass
                        sqlite_datareader.GetString(76), // step size comment
                        sqlite_datareader.GetDecimal(77), // Falloff Height Value
                        sqlite_datareader.GetString(78), // fall off height pass
                        sqlite_datareader.GetString(79), // fall off height comment    
                        sqlite_datareader.GetDecimal(80), // pressure Value
                        sqlite_datareader.GetString(81), // pressure pass
                        sqlite_datareader.GetString(82), // pressure comment
                        sqlite_datareader.GetDecimal(83), // trough depth value
                        sqlite_datareader.GetDecimal(84), // trough width value
                        sqlite_datareader.GetString(85), // trough pass
                        sqlite_datareader.GetString(86), // trough comment
                        sqlite_datareader.GetString(87), // entrapment pass
                        sqlite_datareader.GetString(88), // entrapment comment
                        sqlite_datareader.GetString(89), // marking pass
                        sqlite_datareader.GetString(90), // marking comment
                        sqlite_datareader.GetString(91), // groundingh pass
                        sqlite_datareader.GetString(92), // grounding comment
                        sqlite_datareader.GetInt32(93), // number of Low anchors
                        sqlite_datareader.GetInt32(94), // number of High anchors
                        sqlite_datareader.GetString(95), // number of anchors pass
                        sqlite_datareader.GetString(96), // num anchors comment
                        sqlite_datareader.GetString(97), // Anchor Accessories Pass
                        sqlite_datareader.GetString(98), // Anchor Accessories comment
                        sqlite_datareader.GetString(99), // Anchor Degree pass
                        sqlite_datareader.GetString(100), // anchor degree comment
                        sqlite_datareader.GetString(101), // anchor type pass
                        sqlite_datareader.GetString(102), // anchor type comment
                        sqlite_datareader.GetString(103), // pull strength pass
                        sqlite_datareader.GetString(104), // pull strength comment
                        sqlite_datareader.GetInt32(105), // Exit Number
                        sqlite_datareader.GetString(106), // Exit number pass
                        sqlite_datareader.GetString(107), // Exit Number comment
                        sqlite_datareader.GetString(108), // Exit Visible pass
                        sqlite_datareader.GetString(109), // Exit Visible comment
                        sqlite_datareader.GetInt32(110), // rope size
                        sqlite_datareader.GetString(111), // rope size pass
                        sqlite_datareader.GetString(112), // rope size comment
                        sqlite_datareader.GetString(113), // clamber pass
                        sqlite_datareader.GetString(114), // clamber comment
                        sqlite_datareader.GetString(115), // retention netting pass
                        sqlite_datareader.GetString(116), // retention netting comment
                        sqlite_datareader.GetString(117), // zips pass
                        sqlite_datareader.GetString(118), // zips comment
                        sqlite_datareader.GetString(119), // windows pass
                        sqlite_datareader.GetString(120), // windows comment
                        sqlite_datareader.GetString(121), // Artwork pass
                        sqlite_datareader.GetString(122), // Artwork comment
                        sqlite_datareader.GetString(123), // Thread pass
                        sqlite_datareader.GetString(124), // Thread comment
                        sqlite_datareader.GetString(125), // Fabric pass
                        sqlite_datareader.GetString(126), // Fabric comment
                        sqlite_datareader.GetString(127), // Fire Retardent pass
                        sqlite_datareader.GetString(128), // Fire Retardent comment
                        sqlite_datareader.GetString(129), // blower size comment
                        sqlite_datareader.GetString(130), // blower flaps pass
                        sqlite_datareader.GetString(131), // blower flaps comment
                        sqlite_datareader.GetString(132), // blower finger trap pass
                        sqlite_datareader.GetString(133), // blower finger trap comment
                        sqlite_datareader.GetString(134), // PAT Pass pass
                        sqlite_datareader.GetString(135), // PAT Pass comment
                        sqlite_datareader.GetString(136), // blower visual pass
                        sqlite_datareader.GetString(137), // blower visual comment
                        sqlite_datareader.GetString(138), // blower serial
                        sqlite_datareader.GetString(139), // Risk Assessment
                        sqlite_datareader.GetString(140), // passed inspection
                        sqlite_datareader.GetString(141) // Testimony
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
        I call this quite a bit - Pretty much for the comments of each data point
        It's not ideal, but the full comment is saved to the database and I just can't have a never ending amount of text on the single PDF page.
        I really don't want it over two pages if I can help it.
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
                    PdfPage page = document.AddPage();
                    page.Size = PdfSharp.PageSize.A4;

                    //Set up the graphics
                    GlobalFontSettings.UseWindowsFontsUnderWindows = true;
                    XGraphics gfx = XGraphics.FromPdfPage(page);

                    //Set up the fonts (some are pretty small due to how much data is on the page!).
                    XFont h1font = new XFont("Verdana", 14, XFontStyleEx.Bold);
                    XFont h2font = new XFont("Arial", 12, XFontStyleEx.Bold);
                    XFont regularFont = new XFont("Arial", 8, XFontStyleEx.Regular);
                    XFont regularFontBold = new XFont("Arial", 8, XFontStyleEx.Bold);
                    XFont smallFont = new XFont("Arial", 6, XFontStyleEx.Regular);
                    XTextFormatter tf = new XTextFormatter(gfx);

                    //Draw the content

                    /* Spencer's comment about making the software.*/
                    XRect rect = new XRect(293, 828, 285, 10);
                    gfx.DrawRectangle(XBrushes.SeaShell, rect);
                    tf.DrawString("The software used to generate this report was made by Spencer Elliott.", regularFontBold, XBrushes.Black, rect, XStringFormats.TopLeft);
                    /**********************************************************************************************************************************************************/

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
                    gfx.DrawString("Anchors Between 30-45° Pass/Fail: " + anchorDegreePassFail.Checked.ToString(), regularFont, XBrushes.Black, 312.5, 373);
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

                    //Drawing a rectangle so that I can print the text/string over several lines and not go off page, it's bound to the rectangle confines
                    XRect rect2 = new XRect(15, 750, 549, 73);
                    gfx.DrawRectangle(XBrushes.SeaShell, rect2);
                    tf.DrawString(riskAssessmentNotes.Text, smallFont, XBrushes.Black, rect2, XStringFormats.TopLeft);

                    //Same as above, but different background colour.
                    XRect rect3 = new XRect(15, 812, 564, 9);
                    gfx.DrawRectangle(XBrushes.LavenderBlush, rect3);
                    tf.DrawString("Testimony: " + testimony.Text, smallFont, XBrushes.Black, rect3, XStringFormats.TopLeft);

                    gfx.DrawString("Result: ", h1font, XBrushes.Black, 15, 836);

                    //Dynamic/decision based logic to print "passed" in Green or "failed" in red.
                    if (passedRadio.Checked == false)
                    {
                        gfx.DrawString("Failed Inspection", h1font, XBrushes.Red, 74, 836);
                    }
                    else
                    {
                        gfx.DrawString("Passed Inspection", h1font, XBrushes.Green, 74, 836);
                    }

                    //If there is a photo, might as well add it to the report...
                    if (unitPic.Image != null)
                    {
                        MemoryStream strm = new MemoryStream();
                        Image img = compressImage(unitPic.Image, (double)128, (double)95);
                        img.Save(strm, System.Drawing.Imaging.ImageFormat.Png);
                        XImage xfoto = XImage.FromStream(strm);
                        gfx.DrawImage(xfoto, 455, 15, img.Width, img.Height);
                    }

                    if (inspectorsLogo.Image != null)
                    {
                        MemoryStream strm = new MemoryStream();
                        Image img = compressImage(inspectorsLogo.Image, (double)128, (double)95);
                        img.Save(strm, System.Drawing.Imaging.ImageFormat.Png);
                        XImage xfoto = XImage.FromStream(strm);
                        gfx.DrawImage(xfoto, 315, 15, img.Width, img.Height);
                    }


                    string path = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "RPII Reports ", DateTime.Now.ToString("yyyy-MM-dd"));
                    bool exists = System.IO.Directory.Exists(path);
                    if (!exists)
                    {
                        System.IO.Directory.CreateDirectory(path);
                    }
                    string filename = "RPII Report - " + " - " + uniquereportNum.Text + DateTime.Now.ToString("yyyy-MM-dd HH-mm-ss") + ".pdf";

                    document.Save(path + "\\" + filename);

                    //Blank out the unique report number after the inspection report is created. 
                    uniquereportNum.Text = "";
                    unitPic.Image = null;
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

        void clearRecords()
        {
            records.Rows.Clear();
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
                InspectionCompName.Text = records.Rows[rowIndex].Cells[1].Value.ToString();
                //Do not load the date - You want to re-inspect so the date will be today. (handy really, because I didn't fancy converting from a string to the date time picker type)
                rpiiReg.Text = records.Rows[rowIndex].Cells[3].Value.ToString();
                inspectionLocation.Text = records.Rows[rowIndex].Cells[4].Value.ToString();

                //Unit Details Tab
                unitDescriptionText.Text = records.Rows[rowIndex].Cells[5].Value.ToString();
                ManufacturerText.Text = records.Rows[rowIndex].Cells[6].Value.ToString();
                unitWidthNum.Value = (decimal)records.Rows[rowIndex].Cells[7].Value;
                unitLengthNum.Value = (decimal)records.Rows[rowIndex].Cells[8].Value;
                unitHeightNum.Value = (decimal)records.Rows[rowIndex].Cells[9].Value;
                serialText.Text = records.Rows[rowIndex].Cells[10].Value.ToString();
                unitTypeText.Text = records.Rows[rowIndex].Cells[11].Value.ToString();
                unitOwnerText.Text = records.Rows[rowIndex].Cells[12].Value.ToString();
                unitPic.Image = (Image)records.Rows[rowIndex].Cells[13].FormattedValue; //Can't believe that worked. I thought for sure I would need to convert the image to a string, then convert to an image. 

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
                slidePlatformHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[36].Value;
                slidePlatformHeightComment.Text = records.Rows[rowIndex].Cells[37].Value.ToString();
                slideWallHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[38].Value;
                slideWallHeightComment.Text = records.Rows[rowIndex].Cells[39].Value.ToString();
                slidefirstmetreHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[40].Value;
                slideFirstMetreHeightComment.Text = records.Rows[rowIndex].Cells[41].Value.ToString();
                beyondfirstmetreHeightValue.Value = (decimal)records.Rows[rowIndex].Cells[42].Value;
                beyondfirstmetreHeightComment.Text = records.Rows[rowIndex].Cells[43].Value.ToString();
                slidePermRoofedCheck.Checked = (bool)records.Rows[rowIndex].Cells[44].FormattedValue;
                slidePermRoofedComment.Text = records.Rows[rowIndex].Cells[45].Value.ToString();
                clamberNettingPassFail.Checked = (bool)records.Rows[rowIndex].Cells[46].FormattedValue;
                clamberNettingComment.Text = records.Rows[rowIndex].Cells[47].Value.ToString();
                runoutValue.Value = (decimal)records.Rows[rowIndex].Cells[48].Value;
                runOutPassFail.Checked = (bool)records.Rows[rowIndex].Cells[49].FormattedValue;
                runoutComment.Text = records.Rows[rowIndex].Cells[50].Value.ToString();
                slipsheetPassFail.Checked = (bool)records.Rows[rowIndex].Cells[51].FormattedValue;
                slipsheetComment.Text = records.Rows[rowIndex].Cells[52].Value.ToString();

                //Structure Tab
                seamIntegrityPassFail.Checked = (bool)records.Rows[rowIndex].Cells[53].FormattedValue;
                seamIntegrityComment.Text = records.Rows[rowIndex].Cells[54].Value.ToString();
                lockstitchPassFail.Checked = (bool)records.Rows[rowIndex].Cells[55].FormattedValue;
                lockStitchComment.Text = records.Rows[rowIndex].Cells[56].Value.ToString();
                stitchLengthValue.Value = (int)records.Rows[rowIndex].Cells[57].Value;
                stitchLengthPassFail.Checked = (bool)records.Rows[rowIndex].Cells[58].FormattedValue;
                stitchLengthComment.Text = records.Rows[rowIndex].Cells[59].Value.ToString();
                airLossPassFail.Checked = (bool)records.Rows[rowIndex].Cells[60].FormattedValue;
                airLossComment.Text = records.Rows[rowIndex].Cells[61].Value.ToString();
                wallStraightPassFail.Checked = (bool)records.Rows[rowIndex].Cells[62].FormattedValue;
                wallStraightComment.Text = records.Rows[rowIndex].Cells[63].Value.ToString();
                sharpEdgesPassFail.Checked = (bool)records.Rows[rowIndex].Cells[64].FormattedValue;
                sharpEdgesComment.Text = records.Rows[rowIndex].Cells[65].Value.ToString();
                tubeDistanceValue.Value = (decimal)records.Rows[rowIndex].Cells[66].Value;
                tubeDistancePassFail.Checked = (bool)records.Rows[rowIndex].Cells[67].FormattedValue;
                tubeDistanceComment.Text = records.Rows[rowIndex].Cells[68].Value.ToString();
                stablePassFail.Checked = (bool)records.Rows[rowIndex].Cells[69].FormattedValue;
                stableComment.Text = records.Rows[rowIndex].Cells[70].Value.ToString();
                evacTime.Value = (int)records.Rows[rowIndex].Cells[71].Value;
                evacTimePassFail.Checked = (bool)records.Rows[rowIndex].Cells[72].FormattedValue;
                evacTimeComment.Text = records.Rows[rowIndex].Cells[73].Value.ToString();

                //Structure Cont. Tab
                stepSizeValue.Value = (decimal)records.Rows[rowIndex].Cells[74].Value;
                stepSizePassFail.Checked = (bool)records.Rows[rowIndex].Cells[75].FormattedValue;
                stepSizeComment.Text = records.Rows[rowIndex].Cells[76].Value.ToString();
                falloffHeight.Value = (decimal)records.Rows[rowIndex].Cells[77].Value;
                falloffHeightPassFail.Checked = (bool)records.Rows[rowIndex].Cells[78].FormattedValue;
                falloffHeightComment.Text = records.Rows[rowIndex].Cells[79].Value.ToString();
                pressureValue.Value = (decimal)records.Rows[rowIndex].Cells[80].Value;
                pressurePassFail.Checked = (bool)records.Rows[rowIndex].Cells[81].FormattedValue;
                pressureComment.Text = records.Rows[rowIndex].Cells[82].Value.ToString();

                troughDepthValue.Value = (decimal)records.Rows[rowIndex].Cells[83].Value;
                troughWidthValue.Value = (decimal)records.Rows[rowIndex].Cells[84].Value;
                troughPassFail.Checked = (bool)records.Rows[rowIndex].Cells[85].FormattedValue;
                troughComment.Text = records.Rows[rowIndex].Cells[86].Value.ToString();
                entrapPassFail.Checked = (bool)records.Rows[rowIndex].Cells[87].FormattedValue;
                entrapComment.Text = records.Rows[rowIndex].Cells[88].Value.ToString();
                entrapPassFail.Checked = (bool)records.Rows[rowIndex].Cells[87].FormattedValue;
                entrapComment.Text = records.Rows[rowIndex].Cells[88].Value.ToString();
                markingsPassFail.Checked = (bool)records.Rows[rowIndex].Cells[89].FormattedValue;
                markingsComment.Text = records.Rows[rowIndex].Cells[90].Value.ToString();
                groundingPassFail.Checked = (bool)records.Rows[rowIndex].Cells[91].FormattedValue;
                groundingComment.Text = records.Rows[rowIndex].Cells[92].Value.ToString();

                //Anchorage
                numLowAnchors.Value = (int)records.Rows[rowIndex].Cells[93].Value;
                numHighAnchors.Value = (int)records.Rows[rowIndex].Cells[94].Value;
                numAnchorsPassFail.Checked = (bool)records.Rows[rowIndex].Cells[95].FormattedValue;
                numAnchorsComment.Text = records.Rows[rowIndex].Cells[96].Value.ToString();
                anchorAccessoriesPassFail.Checked = (bool)records.Rows[rowIndex].Cells[97].FormattedValue;
                AnchorAccessoriesComment.Text = records.Rows[rowIndex].Cells[98].Value.ToString();
                anchorDegreePassFail.Checked = (bool)records.Rows[rowIndex].Cells[99].FormattedValue;
                anchorDegreesComment.Text = records.Rows[rowIndex].Cells[100].Value.ToString();
                anchorTypePassFail.Checked = (bool)records.Rows[rowIndex].Cells[101].FormattedValue;
                anchorTypeComment.Text = records.Rows[rowIndex].Cells[102].Value.ToString();
                pullStrengthPassFail.Checked = (bool)records.Rows[rowIndex].Cells[103].FormattedValue;
                pullStrengthComment.Text = records.Rows[rowIndex].Cells[104].Value.ToString();

                //Totally Enclosed Tab
                exitNumberValue.Value = (int)records.Rows[rowIndex].Cells[105].Value;
                exitNumberPassFail.Checked = (bool)records.Rows[rowIndex].Cells[106].FormattedValue;
                exitNumberComment.Text = records.Rows[rowIndex].Cells[107].Value.ToString();
                exitsignVisiblePassFail.Checked = (bool)records.Rows[rowIndex].Cells[108].FormattedValue;
                exitSignVisibleComment.Text = records.Rows[rowIndex].Cells[109].Value.ToString();

                //Materials Tab
                ropesizeValue.Value = (int)records.Rows[rowIndex].Cells[110].Value;
                ropeSizePassFail.Checked = (bool)records.Rows[rowIndex].Cells[111].FormattedValue;
                ropeSizeComment.Text = records.Rows[rowIndex].Cells[112].Value.ToString();
                clamberPassFail.Checked = (bool)records.Rows[rowIndex].Cells[113].FormattedValue;
                clamberComment.Text = records.Rows[rowIndex].Cells[114].Value.ToString();
                retentionNettingPassFail.Checked = (bool)records.Rows[rowIndex].Cells[115].FormattedValue;
                retentionNettingComment.Text = records.Rows[rowIndex].Cells[116].Value.ToString();
                zipsPassFail.Checked = (bool)records.Rows[rowIndex].Cells[117].FormattedValue;
                zipsComment.Text = records.Rows[rowIndex].Cells[118].Value.ToString();
                windowsPassFail.Checked = (bool)records.Rows[rowIndex].Cells[119].FormattedValue;
                windowsComment.Text = records.Rows[rowIndex].Cells[120].Value.ToString();
                artworkPassFail.Checked = (bool)records.Rows[rowIndex].Cells[121].FormattedValue;
                artworkComment.Text = records.Rows[rowIndex].Cells[122].Value.ToString();
                threadPassFail.Checked = (bool)records.Rows[rowIndex].Cells[123].FormattedValue;
                threadComment.Text = records.Rows[rowIndex].Cells[124].Value.ToString();
                fabricPassFail.Checked = (bool)records.Rows[rowIndex].Cells[125].FormattedValue;
                fabricComment.Text = records.Rows[rowIndex].Cells[126].Value.ToString();
                fireRetardentPassFail.Checked = (bool)records.Rows[rowIndex].Cells[127].FormattedValue;
                fireRetardentComment.Text = records.Rows[rowIndex].Cells[128].Value.ToString();

                //Fan Tab
                blowerSizeComment.Text = records.Rows[rowIndex].Cells[129].Value.ToString();
                blowerFlapPassFail.Checked = (bool)records.Rows[rowIndex].Cells[130].FormattedValue;
                blowerFlapComment.Text = records.Rows[rowIndex].Cells[131].Value.ToString();
                blowerFingerPassFail.Checked = (bool)records.Rows[rowIndex].Cells[132].FormattedValue;
                blowerFingerComment.Text = records.Rows[rowIndex].Cells[133].Value.ToString();
                patPassFail.Checked = (bool)records.Rows[rowIndex].Cells[134].FormattedValue;
                patComment.Text = records.Rows[rowIndex].Cells[135].Value.ToString();
                blowerVisualPassFail.Checked = (bool)records.Rows[rowIndex].Cells[136].FormattedValue;
                blowerVisualComment.Text = records.Rows[rowIndex].Cells[137].Value.ToString();
                blowerSerial.Text = records.Rows[rowIndex].Cells[138].Value.ToString();

                //Risk Assessment Tab
                riskAssessmentNotes.Text = records.Rows[rowIndex].Cells[139].Value.ToString();

                //Passed Inspection
                passedRadio.Checked = (bool)records.Rows[rowIndex].Cells[140].FormattedValue; //Should automatically adjust the failed radio

                //Testimony
                testimony.Text = records.Rows[rowIndex].Cells[141].Value.ToString(); //Not really sure why I am loading this - It's static and read only. However, I suppose it may be updated in the future.
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
            if (e.ColumnIndex == 142)
            {
                /*
                Load that record into the main part of the tool
                This is the part that turns an initial inspection into an annual inspection, because you're loading the historic report!
                */
                loadReportIntoApplication(e.RowIndex);
            }
        }

        private void selectLogoBtn_Click(object sender, EventArgs e)
        {
            chooseLogo();
        }
    }
}
