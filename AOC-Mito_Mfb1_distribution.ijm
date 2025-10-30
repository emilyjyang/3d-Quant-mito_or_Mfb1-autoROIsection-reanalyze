//@ File (label="Input directory",style="directory") inputdir
//@ File (label="Output directory",style="directory") outputdir
//@ int(label="Channel for actin --select 0 if none", style = "spinner") Channel_Actin
//@ int(label="Channel for mito -- select 0 if none", style = "spinner") Channel_Mito
//@ int(label="Channel for Mfb1 -- select 0 if none", style = "spinner") Channel_Mfb1
//@ string (label="File type", choices={".czi",".nd2",".ome.tiff"}, style="listBox") Type
//@ Integer(label="crop size",value=150) cropsize
//@ Boolean (label="Batch mode?") arg
//@ Boolean (label="Reanalyze?") REA

list = getFileList(inputdir);

if(Channel_Mito == 0 && Channel_Mfb1 ==0){
	print("No quantifiable channel. Please start again.");
	}

else{
	

for (i=0; i<list.length; i++) {
    showProgress(i+1, list.length);
    filename = inputdir+File.separator + list[i];
    if(Type == ".ome.tiff" ){
    Fname_temp = File.getNameWithoutExtension(filename);
    Fname = File.getNameWithoutExtension(Fname_temp);   
    }
    else{
     Fname = File.getNameWithoutExtension(filename);   	
    	}

    Folder_M_Bratio = outputdir +File.separator+ "0-M_Bratio";
    File.makeDirectory(Folder_M_Bratio);
    Folder_Mask = inputdir+File.separator+ "x-Masks";
    if (Channel_Mito != 0) {
    Folder_IntDenMito = outputdir +File.separator+ "2-SumIntDen-mito";
    File.makeDirectory(Folder_IntDenMito);
    }
    if (Channel_Mfb1 != 0) {
    Folder_IntDenMfb1 = outputdir +File.separator+ "3-SumIntDen-mfb1";
    File.makeDirectory(Folder_IntDenMfb1);
    }      
     
    print("\\Clear");
	roiManager("reset");
	roiManager("Show None");
	run("Clear Results");
	run("Collect Garbage");

    print(filename);
    print(list[i]);
    if (endsWith(filename, Type)) {
        setBatchMode(0);
        roiManager("reset");
        run("Bio-Formats Importer", "open=" + filename + " autoscale color_mode=Default split_channels view=Hyperstack stack_order=XYCZT");
        run("Select None");
        Stack.getDimensions(width, height, ch, slices, frames);
        imagewidth = width;
        imageheight = height;
        imageZstack = slices;
        
        run("Set Measurements...", "bounding redirect=None decimal=9");
		run("Measure");
		px = width / getResult("Width");
        
        
        // Rename channels
        CM =Channel_Mito-1;
        CA =Channel_Actin-1;
        Cmfb =Channel_Mfb1-1;
   		if (Channel_Actin != 0) {   
       		selectWindow(list[i] + " - C="+CA);
       		Actinchannel = getImageID();
   		}
    	if (Channel_Mito != 0) {
      	  	selectWindow(list[i] + " - C="+CM);
    	    Mitochannel = getImageID();
     	}
    	if (Channel_Mfb1 != 0) {
        	selectWindow(list[i] + " - C="+Cmfb);
     		mfbchannel = getImageID();
    	}
		
			selectImage(Actinchannel);
			run("32-bit");
		// Set threshold for mito channel
		if (Channel_Mito != 0) {
		
			selectImage(Mitochannel);
			run("32-bit");
		
			run("Select None");
			run("Threshold...");

			resetThreshold();
			Stack.setSlice(abs(slices/2));
			setAutoThreshold("Shanbhag dark");

			waitForUser("Adjust threshold of mito channel. Inspect the entire Z stack. Press OK when you are done.");
			getThreshold(lower, upper);
			ThresholdUM = lower; 
			print("\\Clear");
			print("Threshold user,"+ThresholdUM);
			selectWindow("Log");
			saveAs("Text", outputdir+ File.separator + Fname + "-RFP-threshold.txt");
			setThreshold(ThresholdUM, 1000000000000000000000000000000.0000);
			run("NaN Background", "stack");
			thresholdedMito = getImageID();
		}
		
		if (Channel_Mfb1 != 0) {
		
			selectImage(mfbchannel);
			run("32-bit");
		
			run("Select None");
			run("Threshold...");

			resetThreshold();
			Stack.setSlice(abs(slices/2));
			setAutoThreshold("Shanbhag dark");

			waitForUser("Adjust threshold of Mfb1 channel. Inspect the entire Z stack. Press OK when you are done.");
			getThreshold(lower, upper);
			ThresholdUMfb = lower; 
			print("\\Clear");
			print("Threshold user,"+ThresholdUMfb);
			selectWindow("Log");
			saveAs("Text", outputdir+ File.separator + Fname + "-GFP-threshold.txt");
			setThreshold(ThresholdUMfb, 1000000000000000000000000000000.0000);
			run("NaN Background", "stack");
			thresholdedMfb1 = getImageID();
		}
		//merge channels
		
		
		if (Channel_Mito != 0 && Channel_Mfb1 == 0) {
		
		selectImage(thresholdedMito);
		Mitochannel_name = getTitle();
		selectImage(Actinchannel);
		Actinchannel_name = getTitle();
		run("Merge Channels...", "c1=["+Mitochannel_name+"] c4=["+Actinchannel_name+"] create");
		mergedImage = getImageID();
		}
		
		if (Channel_Mito == 0 && Channel_Mfb1 != 0) {
		
		selectImage(Actinchannel);
		Actinchannel_name = getTitle();
		selectImage(thresholdedMfb1);
		Mfb1channel_name = getTitle();
		run("Merge Channels...", "c2=["+Mfb1channel_name+"] c4=["+Actinchannel_name+"] create");
		mergedImage = getImageID();
		}
		
		if (Channel_Mito != 0 && Channel_Mfb1 != 0) {
		
		selectImage(thresholdedMito);
		Mitochannel_name = getTitle();
		selectImage(Actinchannel);
		Actinchannel_name = getTitle();
		selectImage(thresholdedMfb1);
		Mfb1channel_name = getTitle();
		run("Merge Channels...", "c1=["+Mitochannel_name+"] c2=["+Mfb1channel_name+"] c4=["+Actinchannel_name+"] create");
		mergedImage = getImageID();
		}
		//reanalyze using ROIs generated from previous analysis. File name must be exactly the same
		if(REA == 1){
			
			//cropping the cells
			roiManager("Open", outputdir+File.separator+Fname+"-CellnumberRoiSet.zip");
			CellRoi = roiManager("count");
			for (j = 0; j < CellRoi; j++) {
			setBatchMode(arg);
			roiManager("reset");
			roiManager("Open", outputdir+File.separator+Fname+"-CellnumberRoiSet.zip");
			selectImage(mergedImage);
			roiManager("select", j);
			roiManager("rename", j+1);
			nCell = j+1;
			pad_nCell = IJ.pad(nCell, 3);

			Roi.getCoordinates(x, y);
		
			run("Select None");
			makeRectangle(x[0]-cropsize/2, y[0]-cropsize/2, cropsize, cropsize);
			run("Duplicate...", "duplicate");
			cropImage = getImageID();
			
			roiManager("reset");
			roiManager("open", outputdir +File.separator+ Fname + "Cell" + pad_nCell+ "-8regions-ROIset.zip")
			cell_m_mask = roiManager("count");
		

		//// Split channels
			selectImage(cropImage);
			cropName = getTitle();
			Stack.getDimensions(width, height, ch, slices, frames);
			run("Split Channels");

			if (Channel_Mito != 0) {
			selectWindow("C1-" +cropName );
			cropMito = getImageID();
			}
		
			if (Channel_Mfb1 != 0) {
			selectWindow("C2-" +cropName );
			cropMfb1 = getImageID();
			}
		
			if (Channel_Actin != 0) {
			selectWindow("C"+ ch +"-" +cropName );
			cropActin = getImageID();
			}
			

		//// 8. measure total red signal in each ROI using 3D ROI manager.
			if (Channel_Mito != 0) {
			SumIntDRFPArray = newArray(cell_m_mask);
			for (m = 0; m < cell_m_mask; m++) {								
				setBatchMode(arg);
				selectImage(cropMito);
				roiManager("Select", m);
				Region_name = Roi.getName();
				run("Duplicate...", "duplicate");
				region_Mito = getImageID();
				run("Clear Outside", "stack");
				setThreshold(ThresholdUM, 1000000000000000000000000000000.0000);
				run("NaN Background", "stack");
				run("3D Manager");
				Ext.Manager3D_Segment(128, 65535);
				Ext.Manager3D_AddImage();
				Ext.Manager3D_Count(nb_obj);
				if (nb_obj > 0) {
					selectImage(region_Mito);
					Ext.Manager3D_Quantif();
					// loop to sum up InD
					sumInDMito = 0;
					for(i=0;i<nb_obj;i++) {
						Ext.Manager3D_Quantif3D(i,"IntDen",InD);
						sumInDMito += InD;
						}
					print("Sum IntDen in Cell"+pad_nCell +Region_name+ sumInDMito);
					SumIntDRFPArray[m]=sumInDMito;
					Ext.Manager3D_CloseResult("Q");
					Ext.Manager3D_Measure();
					Ext.Manager3D_CloseResult("M");
					//Ext.Manager3D_Save(outputdir +Fname+ "-Cell" + pad_nCell + Region_name +"-mito-Roi3D.zip");
					print("\\Clear");
					close("*-3Dseg");
					selectImage(region_Mito);
					close();
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					if (isOpen("Exception")){
					close("Exception");
				}
					}
				else {
					print("mito: n/a");
					selectWindow("Log");
					//saveAs("Text", outputdir +File.separator+ Fname + "Cell" + pad_nCell+ Region_name +"mito_quantif.csv");
					SumIntDRFPArray[m]=0;
					print("\\Clear");
					close("*-3Dseg");
					selectImage(region_Mito);
					close();
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					if (isOpen("Exception")){
					close("Exception");
				}
					}
			
			}
			
			}
			
			//// 9. measure total green signal in each ROI using 3D ROI manager.
			if (Channel_Mfb1 != 0) {
			SumIntDGFPArray = newArray(cell_m_mask);
			for (x = 0; x < cell_m_mask; x++) {								
				setBatchMode(arg);
				selectImage(cropMfb1);
				roiManager("Select", x);
				Region_name = Roi.getName();
				run("Duplicate...", "duplicate");
				region_Mfb1 = getImageID();
				run("Clear Outside", "stack");
				setThreshold(ThresholdUMfb, 1000000000000000000000000000000.0000);
				run("NaN Background", "stack");
				run("3D Manager");
				Ext.Manager3D_Segment(128, 65535);
				Ext.Manager3D_AddImage();
				Ext.Manager3D_Count(nb_obj);
				if (nb_obj > 0) {
					selectImage(region_Mfb1);
					Ext.Manager3D_Quantif();
					//loop to sum up InD
					sumInDMfb1 = 0;
					for(o=0;o<nb_obj;o++) {
						Ext.Manager3D_Quantif3D(o,"IntDen",InDMfb);
						sumInDMfb1 += InDMfb;
						}
					print("Sum IntDen in Cell"+pad_nCell +Region_name+ sumInDMfb1);
					SumIntDGFPArray[x]=sumInDMfb1;
					Ext.Manager3D_CloseResult("Q");
					Ext.Manager3D_Measure();
					Ext.Manager3D_CloseResult("M");
					//Ext.Manager3D_Save(outputdir +Fname+ "-Cell" + pad_nCell + Region_name +"-mito-Roi3D.zip");
					print("\\Clear");
					close("*-3Dseg");
					selectImage(region_Mfb1);
					close();
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					if (isOpen("Exception")){
					close("Exception");
				}
					}
				else {
					print("Mfb1: n/a");
					selectWindow("Log");
					//saveAs("Text", outputdir +File.separator+ Fname + "Cell" + pad_nCell+ Region_name +"-Mfb1_quantif.csv");
					SumIntDGFPArray[x]=0;
					print("\\Clear");
					close("*-3Dseg");
					selectImage(region_Mfb1);
					close();
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					if (isOpen("Exception")){
					close("Exception");
				}
					
					}
			
			}
			
			}
			
			
			
		////close corresponding images
		if (Channel_Mito != 0) {	
			selectImage(cropMito);
			close();
		}
		if (Channel_Mfb1 != 0) {	
			selectImage(cropMfb1);
			close();
		}
		if (Channel_Actin != 0) {
			selectImage(cropActin);
			close();
		}
		
		//save sumintden files
		if (Channel_Mito != 0) {	
			print("\\Clear");
			Array.print(SumIntDRFPArray);
			selectWindow("Log");
			saveAs("Text", Folder_IntDenMito+File.separator + "Re-"+ Fname + "Cell" + pad_nCell+ "-Sum_of_intDen_RFP.txt");
		}
		if (Channel_Mfb1 != 0) {	
			print("\\Clear");
			Array.print(SumIntDGFPArray);
			selectWindow("Log");
			saveAs("Text", Folder_IntDenMfb1+File.separator + "Re-"+ Fname + "Cell" + pad_nCell+ "-Sum_of_intDen_GFP-re.txt");
		}
		
		}
		close("*");			
		}
		//regular analysis
		else {

		//open related mask
		
		run("Bio-Formats Importer", "open=" +Folder_Mask +File.separator+ Fname + "-max_cp_masks.png" + " autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
		Mask = getImageID();
		run("glasbey_on_dark");
		run("Set Measurements...", "min redirect=None decimal=9");
		run("Select None");
		run("Measure");
		cellpose_ROIn = getResult("Max", 1);
		run("Clear Results");
		
		//select cells for cropping
		selectImage(mergedImage);
		run("Z Project...", "projection=[Max Intensity]");
		mergedMAX = getImageID();
		run("Select None");
        Stack.getDimensions(width, height, ch, slices, frames);
        
		if (Channel_Mito != 0) {
		Stack.setChannel(1);
		run("Enhance Contrast", "saturated=0.35");
		}
		
		if (Channel_Mfb1 != 0) {
		Stack.setChannel(2);
		run("Enhance Contrast", "saturated=0.35");
		}
		
		if (Channel_Actin != 0) {
		Stack.setChannel(4);
		run("Enhance Contrast", "saturated=0.35");
		}
		
		
		roiManager("reset");
		RoiBegin = roiManager("count");
		if (RoiBegin > 0) {
			roiManager("delete");
		}
		
		run("Labels...", "color=white font=18 show draw");
		roiManager("Show All with labels");

		run("Select None");
		setTool("point");
		waitForUser("Click on the center of a cell. Add to ROI Manager (keyboard shortcut is t).\n"+
            "Repeat previous step.\n"+
            "When done click OK");
		roiManager("Save", outputdir+File.separator+Fname+"-CellnumberRoiSet.zip");
		CellRoi = roiManager("count");
		MlengthArray = newArray(CellRoi);
		BlengthArray = newArray(CellRoi);
		run("Duplicate...", "use");
		run("Labels...", "color=white font=18 show draw");
		roiManager("Show All with labels");
		run("Flatten");
		saveAs("Tiff", outputdir+File.separator+"0-"+Fname+"-cells-marked.tif");
		close(); close();
		
		//cropping the cells
		for (j = 0; j < CellRoi; j++) {
			setBatchMode(false);
			roiManager("reset");
			roiManager("Open", outputdir+File.separator+Fname+"-CellnumberRoiSet.zip");
			selectImage(mergedImage);
			roiManager("select", j);
			roiManager("rename", j+1);
			nCell = j+1;
			pad_nCell = IJ.pad(nCell, 3);

			Roi.getCoordinates(x, y);
		
			run("Select None");
			makeRectangle(x[0]-cropsize/2, y[0]-cropsize/2, cropsize, cropsize);
			run("Duplicate...", "duplicate");
			cropImage = getImageID();
			
			selectImage(Mask);
			run("Select None");
			makeRectangle(x[0]-cropsize/2, y[0]-cropsize/2, cropsize, cropsize);
			run("Duplicate...", "duplicate");
			cropMask = getImageID();
			
		
		//// 2. draw line along mother and bud
			roiManager("reset");
			print("\\Clear");
			selectImage(cropImage);
			run("Z Project...", "projection=[Max Intensity]");
			cropmergedMAX = getImageID();
			run("Set... ", "zoom=200");
			if (Channel_Actin != 0) {
			Stack.setChannel(3);
			resetMinAndMax();
			run("Enhance Contrast", "saturated=0.1");			
			}
			

		//// measure rotation angle from the mother and bud										
			setTool("line"); run("Line Width...", "line=1");
			waitForUser("Draw a line along mother-bud axis. Start at tip. Click OK when done.");			
			roiManager("Add");
			M_axis = roiManager("count")-1;
			roiManager("Select", M_axis);
			roiManager("Rename", "M-axis-line");
			getLine(M_x1, M_y1, M_x2, M_y2, lineWidth);
			run("Set Measurements...", "redirect=None decimal=9"); 
			run("Measure");
			M_angle = getResult("Angle");
			M_axis_length = getResult("Length");
			RoiManager.selectByName("M-axis-line");
			RoiManager.rotate(90);
			roiManager("Add");
			MP_axis = roiManager("count")-1;
			roiManager("Select", MP_axis);
			roiManager("Rename", "M-axis-line-perpendicular");
			RoiManager.selectByName("M-axis-line");	
			getLine(MP_x1, MP_y1, MP_x2, MP_y2, lineWidth);
			
			waitForUser("Draw a line along mother-bud axis in the bud. Start at neck. Click OK when done.");		
			roiManager("Add");
			B_axis = roiManager("count")-1;
			roiManager("Select", B_axis);
			roiManager("Rename", "B-axis-line");
			getLine(B_x1, B_y1, B_x2, B_y2, lineWidth);
			run("Set Measurements...", "redirect=None decimal=9"); 
			run("Measure");
			B_angle = getResult("Angle");
			B_axis_length = getResult("Length");
			RoiManager.selectByName("B-axis-line");	
			RoiManager.rotate(90);	
			roiManager("Add");
			BP_axis = roiManager("count")-1;
			roiManager("Select", BP_axis);
			roiManager("Rename", "B-axis-line-perpendicular");
			RoiManager.selectByName("B-axis-line");	
			getLine(BP_x1, BP_y1, BP_x2, BP_y2, lineWidth);
			roiManager("Save", outputdir+File.separator+Fname + "Cell" + pad_nCell+ "-M_B-axisRoiSet.zip");
			

		//// 4. draw ROI around mother and bud & 5 regions
			roiManager("reset");
			selectImage(cropmergedMAX);
			selectImage(cropMask);
			run("Set... ", "zoom=200");
			
			setTool("wand");
			waitForUser("Select mother cell. Press OK when you are done.");
			roiManager("Add");
			r_M = roiManager("count")-1;
			
			roiManager("Select", r_M);
			roiManager("Rename", "mother");

			waitForUser("Select bud cell. Press OK when you are done.");
			roiManager("Add");
			r_B = roiManager("count")-1;
			roiManager("Select", r_B);
			roiManager("Rename", "bud");

			roiManager("Select", newArray(r_M,r_B));
			roiManager("Combine");
			roiManager("Add");
			r_cell = roiManager("count")-1;
			roiManager("Select", r_cell);
			roiManager("Rename", "cell");

		//// get mother length
			roiManager("Select", r_M);
			run("Clear Results");
			run("Set Scale...", "distance="+ px +" known=1 unit=micron");
			run("Set Measurements...", "feret's redirect=None decimal=9");
			run("Measure");
			M_length = getValue("Feret");
			print("mother length (um), "+ M_length);
			MlengthArray[j] = M_length;

		//// get bud length
			roiManager("Select", r_B);
			run("Clear Results");
			run("Set Scale...", "distance="+ px +" known=1 unit=micron");
			run("Set Measurements...", "feret's redirect=None decimal=9");
			run("Measure");
			B_length = getValue("Feret");
			print("bud length (um), "+ B_length);
			BlengthArray[j] = B_length;

		//// save bud/mother ratio
			BMratio = B_length / M_length;
			print("bud/mother ratio, "+ BMratio);


		//// save line measurement as a file and clear ROI manager
			selectWindow("Log");
			saveAs("Text", Folder_M_Bratio+ File.separator + Fname + "Cell" + pad_nCell+ "-M_B-length.txt");
			print("\\Clear");

		//// append mother or bud length to one file
			if (!File.exists(Folder_M_Bratio+ File.separator + Fname + "-Mother_length-append.csv")) {
			print(M_length);
			saveAs("txt", Folder_M_Bratio+ File.separator + Fname + "-Mother_length-append.csv");
			close("Log");
			};
			else {
			File.append(M_length, Folder_M_Bratio+ File.separator + Fname + "-Mother_length-append.csv");
			print("\\Clear");
			}
			
			if (!File.exists(Folder_M_Bratio+ File.separator + Fname + "-Bud_length-append.csv")) {
			print(B_length);
			saveAs("txt", Folder_M_Bratio+ File.separator + Fname + "-Bud_length-append.csv");
			close("Log");
			};
			else {
			File.append(B_length, Folder_M_Bratio+ File.separator + Fname + "-Bud_length-append.csv");
			print("\\Clear");
			}		
			
			run("Clear Results");

		////select mother ROI and divided to 3 ROIs
			run("Clear Results");
			run("Select None");
			
			r_cord = sqrt((MP_x2-MP_x1)*(MP_x2-MP_x1)+(MP_y2-MP_y1)*(MP_y2-MP_y1));
			x_delta = (M_axis_length*px/3)/r_cord*(MP_y1-MP_y2);
			y_delta = (M_axis_length*px/3)/r_cord*(MP_x2-MP_x1);
			

			
			for (r = 1; r <=3 ; r++) {
				
					x1_para = (MP_x1-2*(MP_x2-MP_x1)/M_axis_length)+ x_delta;
					y1_para = (MP_y1-2*(MP_y2-MP_y1)/M_axis_length)+ y_delta;
					x2_para = (MP_x2+2*(MP_x2-MP_x1)/M_axis_length)+ x_delta; 
					y2_para = (MP_y2+2*(MP_y2-MP_y1)/M_axis_length)+ y_delta;
					makeRotatedRectangle(x1_para-(r-1)*x_delta, y1_para-(r-1)*y_delta, x2_para-(r-1)*x_delta, y2_para-(r-1)*y_delta, M_axis_length*px/3);
					roiManager("Add");
					r_temp = roiManager("count")-1;
					roiManager("Select", newArray(r_M,r_temp));
					roiManager("AND");
					roiManager("Add");
					newROI = roiManager("count")-1;
					roiManager("Select",newROI);
					roiManager("Rename", "MotherR"+r);
					roiManager("Select", r_temp);
					roiManager("Delete");
				
				
			}
			
		////select bud ROI and divided to 2 ROIs.
			run("Clear Results");
			run("Select None");
			
			r_cord_B = sqrt((BP_x2-BP_x1)*(BP_x2-BP_x1)+(BP_y2-BP_y1)*(BP_y2-BP_y1));
			x_delta_B = (B_axis_length*px/2)/r_cord_B*(BP_y1-BP_y2);
			y_delta_B = (B_axis_length*px/2)/r_cord_B*(BP_x2-BP_x1);
			

			
			for (r = 1; r <=2 ; r++) {
				
					x1_para_B = (BP_x1-2*(BP_x2-BP_x1)/B_axis_length)+1/2*x_delta_B;
					y1_para_B = (BP_y1-2*(BP_y2-BP_y1)/B_axis_length)+1/2*y_delta_B;
					x2_para_B = (BP_x2+2*(BP_x2-BP_x1)/B_axis_length)+1/2*x_delta_B; 
					y2_para_B = (BP_y2+2*(BP_y2-BP_y1)/B_axis_length)+1/2*y_delta_B;
					makeRotatedRectangle(x1_para_B-(r-1)*x_delta_B, y1_para_B-(r-1)*y_delta_B, x2_para_B-(r-1)*x_delta_B, y2_para_B-(r-1)*y_delta_B, B_axis_length*px/2);
					roiManager("Add");
					r_temp = roiManager("count")-1;
					roiManager("Select", newArray(r_B,r_temp));
					roiManager("AND");
					roiManager("Add");
					newROI = roiManager("count")-1;
					roiManager("Select",newROI);
					roiManager("Rename", "BudR"+r);
					roiManager("Select", r_temp);
					roiManager("Delete");


			}
			roiManager("save", outputdir +File.separator+ Fname + "Cell" + pad_nCell+ "-8regions-ROIset.zip")
			cell_m_mask = roiManager("count");
			selectImage(cropImage);
			close();
			selectImage(cropMask);
			close();
			selectImage(cropmergedMAX);
			close();
		}

		//Anayzing all cells after ROIs are generated
		//cropping the cells
			roiManager("reset");
			roiManager("Open", outputdir+File.separator+Fname+"-CellnumberRoiSet.zip");
			CellRoi = roiManager("count");
			for (j = 0; j < CellRoi; j++) {
			setBatchMode(arg);
			roiManager("reset");
			roiManager("Open", outputdir+File.separator+Fname+"-CellnumberRoiSet.zip");
			selectImage(mergedImage);
			roiManager("select", j);
			roiManager("rename", j+1);
			nCell = j+1;
			pad_nCell = IJ.pad(nCell, 3);

			Roi.getCoordinates(x, y);
		
			run("Select None");
			makeRectangle(x[0]-cropsize/2, y[0]-cropsize/2, cropsize, cropsize);
			run("Duplicate...", "duplicate");
			cropImage = getImageID();
			
			roiManager("reset");
			roiManager("open", outputdir +File.separator+ Fname + "Cell" + pad_nCell+ "-8regions-ROIset.zip")
			cell_m_mask = roiManager("count");
		

		//// Split channels
			selectImage(cropImage);
			cropName = getTitle();
			Stack.getDimensions(width, height, ch, slices, frames);
			run("Split Channels");

			if (Channel_Mito != 0) {
			selectWindow("C1-" +cropName );
			cropMito = getImageID();
			}
		
			if (Channel_Mfb1 != 0) {
			selectWindow("C2-" +cropName );
			cropMfb1 = getImageID();
			}
		
			if (Channel_Actin != 0) {
			selectWindow("C"+ ch +"-" +cropName );
			cropActin = getImageID();
			}
			

		//// 8. measure total red signal in each ROI using 3D ROI manager.
			if (Channel_Mito != 0) {
			SumIntDRFPArray = newArray(cell_m_mask);
			for (m = 0; m < cell_m_mask; m++) {								
				setBatchMode(arg);
				selectImage(cropMito);
				roiManager("Select", m);
				Region_name = Roi.getName();
				run("Duplicate...", "duplicate");
				region_Mito = getImageID();
				run("Clear Outside", "stack");
				setThreshold(ThresholdUM, 1000000000000000000000000000000.0000);
				run("NaN Background", "stack");
				run("3D Manager");
				Ext.Manager3D_Segment(128, 65535);
				Ext.Manager3D_AddImage();
				Ext.Manager3D_Count(nb_obj);
				if (nb_obj > 0) {
					selectImage(region_Mito);
					Ext.Manager3D_Quantif();
					// loop to sum up InD
					sumInDMito = 0;
					for(a=0;a<nb_obj;a++) {
						Ext.Manager3D_Quantif3D(a,"IntDen",InD);
						sumInDMito += InD;
						}
					print("Sum IntDen in Cell"+pad_nCell +Region_name+ sumInDMito);
					SumIntDRFPArray[m]=sumInDMito;
					Ext.Manager3D_CloseResult("Q");
					Ext.Manager3D_Measure();
					Ext.Manager3D_CloseResult("M");
					//Ext.Manager3D_Save(outputdir +Fname+ "-Cell" + pad_nCell + Region_name +"-mito-Roi3D.zip");
					print("\\Clear");
					close("*-3Dseg");
					selectImage(region_Mito);
					close();
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					if (isOpen("Exception")){
					close("Exception");
				}
					}
				else {
					print("mito: n/a");
					selectWindow("Log");
					//saveAs("Text", outputdir +File.separator+ Fname + "Cell" + pad_nCell+ Region_name +"mito_quantif.csv");
					SumIntDRFPArray[m]=0;
					print("\\Clear");
					close("*-3Dseg");
					selectImage(region_Mito);
					close();
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					if (isOpen("Exception")){
					close("Exception");
				}
					}
			}
			}
					
					//// 9. measure total green signal in each ROI using 3D ROI manager.
			if (Channel_Mfb1 != 0) {
			SumIntDGFPArray = newArray(cell_m_mask);
			for (x = 0; x < cell_m_mask; x++) {								
				setBatchMode(arg);
				selectImage(cropMfb1);
				roiManager("Select", x);
				Region_name = Roi.getName();
				run("Duplicate...", "duplicate");
				region_Mfb1 = getImageID();
				run("Clear Outside", "stack");
				setThreshold(ThresholdUMfb, 1000000000000000000000000000000.0000);
				run("NaN Background", "stack");
				run("3D Manager");
				Ext.Manager3D_Segment(128, 65535);
				Ext.Manager3D_AddImage();
				Ext.Manager3D_Count(nb_obj);
				if (nb_obj > 0) {
					selectImage(region_Mfb1);
					Ext.Manager3D_Quantif();
					//loop to sum up InD
					sumInDMfb1 = 0;
					for(o=0;o<nb_obj;o++) {
						Ext.Manager3D_Quantif3D(o,"IntDen",InDMfb);
						sumInDMfb1 += InDMfb;
						}
					print("Sum IntDen in Cell"+pad_nCell +Region_name+ sumInDMfb1);
					SumIntDGFPArray[x]=sumInDMfb1;
					Ext.Manager3D_CloseResult("Q");
					Ext.Manager3D_Measure();
					Ext.Manager3D_CloseResult("M");
					//Ext.Manager3D_Save(outputdir +Fname+ "-Cell" + pad_nCell + Region_name +"-mito-Roi3D.zip");
					print("\\Clear");
					close("*-3Dseg");
					selectImage(region_Mfb1);
					close();
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					if (isOpen("Exception")){
					close("Exception");
				}
					}
				else {
					print("Mfb1: n/a");
					selectWindow("Log");
					//saveAs("Text", outputdir +File.separator+ Fname + "Cell" + pad_nCell+ Region_name +"-Mfb1_quantif.csv");
					SumIntDGFPArray[x]=0;
					print("\\Clear");
					close("*-3Dseg");
					selectImage(region_Mfb1);
					close();
					Ext.Manager3D_Reset();
					Ext.Manager3D_Close();
					if (isOpen("Exception")){
					close("Exception");
				}
					
					}
			
			}
			}
			
			////close corresponding images
			if (Channel_Mito != 0) {	
			selectImage(cropMito);
			close();
			}
			if (Channel_Mfb1 != 0) {	
			selectImage(cropMfb1);
			close();
			}
			if (Channel_Actin != 0) {
			selectImage(cropActin);
			close();
			}
		
			//save sumintden files
			if (Channel_Mito != 0) {	
			print("\\Clear");
			Array.print(SumIntDRFPArray);
			selectWindow("Log");
			saveAs("Text", Folder_IntDenMito+File.separator + Fname + "Cell" + pad_nCell+ "-Sum_of_intDen_RFP.txt");
			}
			if (Channel_Mfb1 != 0) {	
			print("\\Clear");
			Array.print(SumIntDGFPArray);
			selectWindow("Log");
			saveAs("Text", Folder_IntDenMfb1+File.separator + Fname + "Cell" + pad_nCell+ "-Sum_of_intDen_GFP.txt");
			}
		
		}
		close("*");	
			
				
		//save cell length of mother & bud cell
		print("\\Clear");
		Array.print(MlengthArray);
		selectWindow("Log");
		saveAs("Text", Folder_M_Bratio+File.separator + Fname + "-Mother_length_allCells.csv");
		print("\\Clear");
		Array.print(BlengthArray);
		selectWindow("Log");
		saveAs("Text", Folder_M_Bratio+File.separator + Fname + "-Bud_length_allCells.csv");
	
	close("*");			
    

       
        }
	}
else{ print("There is no more image to analyse.");
}


 
}
}
