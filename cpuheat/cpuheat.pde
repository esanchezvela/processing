/*
  Copyright 2010-2012 Enrique Sanchez-Vela

    This file is part of DISKHEAT

    DISKHEAT is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/
    
 import netscape.javascript.*; 
 import javax.swing.*;
 import javax.swing.filechooser.*;
 
 Disk disk;
 HashMap  values, sample_time, cpus;
 ArrayList array_disks, sample_times;

 float max_value = 100.0;
 float min_value = 0.0;

 int GridSize = 7;
 int XaxisOffset = 80;
 int YaxisOffset = 100;
 int Yheader = (YaxisOffset/4);
 PFont font;

 String servername = "nodata";
 String iostatfile = "nodata";
 String datestr = "nodata";

 int centerX = 0;
 int centerY = 0;
 int offsetX = 0;
 int offsetY = 0;
 int mouseMove = 0;
 int xsize, ysize;

void setup() {
   font = createFont("LinBiolinumSlanted",18);
   try {
      JSObject window = (JSObject) JSObject.getWindow(this);
      servername  = param("servername"); 
      iostatfile  = param("iostatfile");
      datestr    = param("datestr"); 
   } catch (Exception ignore) {
     iostatfile = "nodata";
     servername = "testserver";
     datestr = "10/12/2012";  
     cursor(HAND);
     smooth();
     newdrawing();
   } 

   loadfile(servername, iostatfile);
   xsize = ( sample_times.size() > 73 ? sample_times.size() : 73 );
   size( (xsize+40)*GridSize, (ysize+40)*GridSize );
}
 
void newdrawing() {  
   String[] info;    
       try { 
         UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()); 
     } catch (Exception e) { 
         e.printStackTrace();  
     } 
 
     // create a file chooser 
     final JFileChooser fc = new JFileChooser("/Users/exsanche/processing/cpuheat/data"); 
 
     // in response to a button click: 
     int returnVal = fc.showOpenDialog(this); 
     
     if (returnVal == JFileChooser.APPROVE_OPTION) { 
        File file = fc.getSelectedFile(); 
        if (file.getName().endsWith("nmon")) { 
            iostatfile =  file.getName();
            info = splitTokens(iostatfile,".");
            iostatfile = file.getPath();
            servername = info[0];
            datestr = info[1];
         }         
      } else { 
         println("Open command cancelled by user."); 
         noLoop();
      }
}

void draw() {
  background(255);

  String nameOfdisk, timeOfsample, valueOfsample;
  float sample_value = 0;
  color fcolor=0;
  Disk cpu; 
  
  int x = mouseX - XaxisOffset - centerX;
  int y = mouseY - YaxisOffset - centerY;

  int xo = pmouseX - XaxisOffset - centerX;
  int yo = pmouseY - YaxisOffset - centerY;
  
  fill(255,255,255);
  stroke(0);
  if (mousePressed == true && (mouseButton == RIGHT  ) ) {
        centerX = mouseX-offsetX;
        centerY = mouseY-offsetY;
  }

  translate(centerX,centerY);
  
  rect(XaxisOffset,Yheader,(xsize)*GridSize, Yheader * 2 );
  rect( XaxisOffset/2, Yheader, GridSize*4, Yheader * 2); 
  fill(0,0,0);
  textFont(font,12);
  text("CPU Stats for "+servername+" on "+datestr,XaxisOffset+(xsize/4)*GridSize, Yheader * 2); 
  text("(move the mouse over grid to display disk information and usage)",XaxisOffset+(xsize/4)*GridSize-30, Yheader * 2+14); 
  drawKeyChart();

  Object[] cpu_list = cpus.keySet().toArray();
  String[] s = new String[cpus.size()];
  String cpu_label;
  ArrayList cpu_data;
  
  int cpu_counter = 0;
  
  while ( cpu_counter < cpus.size() ) {
      s[cpu_counter] = (String) cpu_list[cpu_counter];
      cpu_counter++;
  }

  s = sort(s);
  
  cpu_counter = 0;
  
  while (cpu_counter < cpus.size() ) {
    // Map.Entry cpu_map = (Map.Entry)i.next();
    cpu_label = (String) s[cpu_counter];
    cpu_data = (ArrayList) cpus.get(cpu_label);
    colorMode(RGB, 255);
    for (int cpu_index = 0; cpu_index < cpu_data.size(); cpu_index++) {
      for (int time_index=0; time_index < sample_times.size(); time_index++) {
        cpu = (Disk) cpu_data.get(cpu_index);
        values = (HashMap) cpu.get_values();
        // check whether the sample interval exists for the current disk.
        if ( values.containsKey(sample_times.get(time_index))) {
          // grab the sample value for the disk/sample interval tuple.
          sample_value = Float.valueOf((String) values.get(sample_times.get(time_index)));
          colorMode(HSB,100);
          // sanity check in case iostat decides to give a funny value
          //sample_value = (sample_value > 100 ? 100 : sample_value);
	  fcolor = lerpColor(#0000FF,#FF0000,sample_value/max_value);
          colorMode(RGB,255);
        } else {
          // if the sample interval does not exist for the disk, chose black.
          fcolor=0;
        }
        fill(fcolor);
        rect(XaxisOffset+time_index*GridSize,YaxisOffset+cpu_index*GridSize+((cpu_data.size()+1)*cpu_counter)*GridSize,GridSize,GridSize);
      }
    }
    fill(255,255,255);
    rect( XaxisOffset+(xsize+2)*GridSize, YaxisOffset, GridSize*18, (cpus.size()*cpu_data.size()+14)*GridSize);
    
    rect( XaxisOffset/2, YaxisOffset,GridSize * 4, ( (cpus.size()*cpu_data.size()+9)*GridSize));
    fill(0,0,0);
    text("C\nP\nU\nS", XaxisOffset/2 + GridSize, YaxisOffset + GridSize * 3);

    int time_index;    int cpu_index;
    // if the current mouse position is the same as in the previous refresh cycle.
    if ( y == yo && x == xo ) {
      // if the mouse is over the disk grid.
      if ( x > 0 && x < sample_times.size()*GridSize  && y > 0 && y < cpus.size()*(cpu_data.size()+1)*GridSize ) {
        // time_index is the index to the nth interval to be ploted.
        time_index = x / GridSize;
        // cpu_index is the index to the cpu parameter to be worked on.
        cpu_index = y / ((cpu_data.size()+1)*GridSize);
        cpu_label = s[cpu_index];

        cpu_data = (ArrayList) cpus.get(cpu_label);
        cpu_index = ( y - cpu_index*(cpu_data.size()+1)*GridSize)/GridSize;
        
        if ( cpu_index < cpu_data.size() ) { 
          Disk c = (Disk) cpu_data.get(cpu_index);
          nameOfdisk   =  (String) c.get_name();
          timeOfsample =  (String) sample_times.get(time_index);
          HashMap v = (HashMap) c.get_values();
          if ( values.containsKey(timeOfsample)) {
            valueOfsample = (String) v.get(timeOfsample);
          } else {
            valueOfsample = "N/A";
          }
          fill(0,0,0);
          textFont(font,12);
          text(cpu_label, XaxisOffset + (xsize+4) * GridSize, Yheader * 3 + 2 * GridSize);
          // text(" "+nameOfdisk,XaxisOffset+(xsize+2.5)*GridSize,YaxisOffset+y+2); 
          text(" "+nameOfdisk+"\ntime="+timeOfsample+"\nvalue="+valueOfsample,XaxisOffset+(xsize+2.5)*GridSize,YaxisOffset+y+2); 

          delay(150);       
        } 
      }
    }
    cpu_counter++;  
  }
}


void drawKeyChart() {
  color fcolor; 
  
  // Create Chart's key table.
  colorMode(HSB,100);
  fcolor = lerpColor(#0000FF,#FF0000,0);
  fill(fcolor);
  rect ( XaxisOffset + (xsize/12) * GridSize, Yheader * 3 + GridSize , GridSize, GridSize);
  fcolor = lerpColor(#0000FF,#FF0000,0.25);
  fill(fcolor);
  rect ( XaxisOffset + (xsize/12) * GridSize + 10 * GridSize, Yheader * 3 + GridSize , GridSize, GridSize);
  fcolor = lerpColor(#0000FF,#FF0000,0.5);
  fill(fcolor);
  rect ( XaxisOffset + (xsize/12) * GridSize + 27 * GridSize, Yheader * 3 + GridSize , GridSize, GridSize);
  fcolor = lerpColor(#0000FF,#FF0000,0.75);
  fill(fcolor);
  rect ( XaxisOffset + (xsize/12) * GridSize + 44 * GridSize, Yheader * 3 + GridSize , GridSize, GridSize);
  fcolor = lerpColor(#0000FF,#FF0000,1);
  fill(fcolor);
  rect ( XaxisOffset + (xsize/12) * GridSize + 61 * GridSize, Yheader * 3 + GridSize , GridSize, GridSize);
  fill(0,0,0);
  text( int(min_value), XaxisOffset+(xsize/12 + 2) * GridSize, Yheader * 3 + 2 * GridSize);
  text(int((max_value * 25) / 100) , XaxisOffset + (xsize/12) * GridSize + 12 * GridSize, Yheader * 3 + 2 * GridSize);
  text(int(max_value / 2), XaxisOffset + (xsize/12) * GridSize + 29 * GridSize, Yheader * 3 + 2 * GridSize);
  text(int((75 *  max_value ) / 100), XaxisOffset + (xsize/12) * GridSize + 46 * GridSize, Yheader * 3 + 2 * GridSize);
  text(int(max_value), XaxisOffset + (xsize/12) * GridSize + 63 * GridSize, Yheader * 3 + 2 * GridSize);
 
}

void mouseReleased() {
  if ( mouseMove == 0 ) {
     delay(2000);
     loop();
  }
}

void keyPressed() {
  // zoom
  if (keyCode == UP) { centerX = 0; centerY = 0; }
}
  

Boolean checkFloat(String value) {
  try {
     Float.parseFloat(value); 
  }
  catch(NumberFormatException e){
       return false;
  }
  return true;            
}  
  
void loadfile(String servername, String iostatfile ) {
  String[] lines, current_line;
  String disk_label, sample_value = "0", interval, sample_time_s = "00:00:00";
  Disk cpu_stats, ldisk;
  
  cpus = new HashMap();
  sample_time = new HashMap();
  sample_times = new ArrayList();

  String cpu_label;
  ArrayList cpu_list;
  
  
try {       
    String read_label = "CPU[0-9].*";
    ysize = 0;
    lines = loadStrings(iostatfile);

    for (int i = 0; i < lines.length; i++) {
      current_line = splitTokens(lines[i],",");
      // discard empty lines and comments.
      if ( current_line.length > 0 && (current_line[0].indexOf("#") != 0) &&  (current_line[0].matches("ZZZZ") || current_line[0].matches(read_label) ) )   {
         if ( current_line[0].matches("ZZZZ")  ) {
            sample_time.put(current_line[1],current_line[2]);
            sample_times.add(current_line[2]);
          } else {
            // first line of read_label tag.
            if ( ! current_line[1].matches("T[0-9].*")    ) {
              // This is for a new CPU, so let's create a whole new array of data points
              cpu_list = new ArrayList();
              cpus.put(current_line[0], cpu_list);
              
              for ( int j = 2; j < current_line.length; j++ ) {  
                cpu_stats = new Disk(current_line[j]);
                cpu_list.add(cpu_stats);
              }

            } else {
              ysize++;
              cpu_label = current_line[0];
              interval = current_line[1];
              
              cpu_list = (ArrayList) cpus.get(cpu_label);

              for ( int j = 0; j < cpu_list.size(); j++) {
                ldisk = (Disk) cpu_list.get(j);
                values = ldisk.get_values();
                sample_value = current_line[j+2];
                
                if ( checkFloat(sample_value) ) {
                  values.put(sample_time.get(interval), sample_value);
                  // keep a record of the min and max values on the data.      
                  max_value = ( Float.valueOf(sample_value) > max_value ? Float.valueOf(sample_value) : max_value);
                  min_value = ( Float.valueOf(sample_value) < min_value ? Float.valueOf(sample_value) : min_value);
                }
              }  // for int j=2 ....
            } // if-then-else
        }
              
      }
    }   
  } catch (Exception ignore) {
     noLoop();
  }
}


