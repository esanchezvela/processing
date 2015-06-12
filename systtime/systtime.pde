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
 HashMap values, cpus; 
 ArrayList sample_times;

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
   ysize = cpus.size() + 4; 
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
     final JFileChooser fc = new JFileChooser("/Users/exsanche/Documents/esv/systtime/data"); 
 
     // in response to a button click: 
     int returnVal = fc.showOpenDialog(this); 
     
     if (returnVal == JFileChooser.APPROVE_OPTION) { 
        File file = fc.getSelectedFile(); 
        if (file.getName().endsWith("txt")) { 
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

  Iterator cpuIterator = cpus.keySet().iterator();
  String[] s = new String[cpus.size()];
  String cpu_label;
  ArrayList cpu_data;
  
  int i = 0;
  while ( cpuIterator.hasNext() ) {
       s[i++] = (String) cpuIterator.next();
  }

  s = sort(s);
  
  // Map.Entry cpu_map = (Map.Entry)i.next();
  colorMode(RGB, 255);
  for (int cpu_index = 0; cpu_index < cpus.size(); cpu_index++) {
      for (int time_index=0; time_index < sample_times.size(); time_index++) {
          // cpu_label = (String) s[cpu_index];
          cpu = (Disk) cpus.get(s[cpu_index]);
          values = (HashMap) cpu.get_values();
          // check whether the sample interval exists for the current disk.
          if ( values.containsKey(sample_times.get(time_index))) {
              // grab the sample value for the disk/sample interval tuple.
              sample_value = Float.valueOf((String) values.get(sample_times.get(time_index)));
              colorMode(HSB,100);
              // sanity check in case the tool decides to give a funny value
              sample_value = (sample_value > 100 ? 100 : sample_value);
	      fcolor = lerpColor(#0000FF,#FF0000,sample_value/max_value);
              colorMode(RGB,255);
          } else {
              // if the sample interval does not exist for the disk, chose black.
              fcolor=0;
          }
          fill(fcolor);
          rect(XaxisOffset+time_index*GridSize,YaxisOffset+cpu_index*GridSize,GridSize,GridSize);
      }
  }
  fill(255,255,255);
  rect( XaxisOffset+(xsize+2)*GridSize, YaxisOffset, GridSize*18, (cpus.size()+5)*GridSize);
    
  rect( XaxisOffset/2, YaxisOffset,GridSize * 4, ( (cpus.size()+5)*GridSize));
  fill(0,0,0);
  text("C\nP\nU\nS", XaxisOffset/2 + GridSize, YaxisOffset + GridSize * 3);

  int time_index;    int cpu_index;
  // if the current mouse position is the same as in the previous refresh cycle.
  if ( y == yo && x == xo ) {
      // if the mouse is over the disk grid.
      if ( x > 0 && x < sample_times.size()*GridSize  && y > 0 && y < cpus.size()*GridSize) {
        // time_index is the index to the nth interval to be ploted.
        time_index = x / GridSize;
        // cpu_index is the index to the cpu parameter to be worked on.
        cpu_index = y / (GridSize);
        
        cpu_label = s[cpu_index];

        // cpu_data = (ArrayList) cpus.get(cpu_label);
        // cpu_index = ( y - cpu_index*GridSize)/GridSize;
        
        if ( cpu_index < cpus.size() ) { 
            cpu = (Disk)cpus.get(s[cpu_index]);
            nameOfdisk   =  (String) cpu.get_name();
            timeOfsample =  (String) sample_times.get(time_index);
            HashMap v = (HashMap) cpu.get_values();
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
    String  sample_time, sample_value, cpu_label;
    Disk cpu;
    Float max_value = 100.;
    Float min_value = 0.;
    
  
    try {       
        String read_label = "[0-2][0-9]:[0-5].*";
        ysize = 0;
        lines = loadStrings(iostatfile);
        sample_times = new ArrayList();
        cpus = new HashMap();
        
        for (int i = 0; i < lines.length; i++) {
            current_line = splitTokens(lines[i]," ");
            // discard empty lines and comments.
            if ( current_line.length > 0 && current_line[0].matches(read_label) && current_line[1].matches("[0-9][0-9]*") )    {
                sample_time = current_line[0];
                cpu_label   = current_line[1];
                if ( ! sample_times.contains(sample_time) ) {
                    sample_times.add(sample_time);
                }

                // first line of read_label tag.
                if ( ! cpu_label.matches("all|CPU") ) {
                    if (  cpus.get(cpu_label) == null ) {
                        // This is for a new CPU, so let's create a whole new array of data points
                        cpu = new Disk(cpu_label);
                        cpus.put(cpu_label,cpu);
                    } 
      
                    cpu = (Disk) cpus.get(cpu_label);
                    values = cpu.get_values();
                    sample_value = current_line[4];
                      
                    if ( checkFloat(sample_value) ) {
                        values.put(sample_time, sample_value);
                        // keep a record of the min and max values on the data.      
                        max_value = ( Float.valueOf(sample_value) > max_value ? Float.valueOf(sample_value) : max_value);
                        min_value = ( Float.valueOf(sample_value) < min_value ? Float.valueOf(sample_value) : min_value);
                    }
                } // if-then-else
            }
        } // for i... 
    } catch (Exception ignore) {
         noLoop();
    }

}



