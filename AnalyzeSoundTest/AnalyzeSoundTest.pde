/************************************************************
______            _    ______     _       _    _             
| ___ \          | |   |  _  \   | |     | |  | |            
| |_/ / ___  __ _| |_  | | | |___| |_ ___| | _| |_ ___  _ __ 
| ___ \/ _ \/ _` | __| | | | / _ \ __/ _ \ |/ / __/ _ \| '__|
| |_/ /  __/ (_| | |_  | |/ /  __/ ||  __/   <| || (_) | |   
\____/ \___|\__,_|\__| |___/ \___|\__\___|_|\_\\__\___/|_|   
                                                             
  ************************************************************/

import ddf.minim.analysis.*; //required libs
import ddf.minim.*;
import ddf.minim.spi.*;
import java.util.Arrays;
import java.util.Map;
import javax.swing.*;

/************************
* Audio Logic Variables *
*************************/
Minim minim; //audio processor object
AudioPlayer jingle; //audio source (playback)
AudioSample jingle2; //audio source (pre analysis)
String filename = "ww2.mp3";

FFT fft; //FFT to use
float[] spectrum = new float[1024 / 2 + 1]; //hold all observed values from the fft transform
float[] lastSpectrum = new float[1024 / 2 + 1]; //previous values
float[][] spectras; //hold all values from the fft transforms
float[] amps; //hold relative amplitudes of chunks
float flux ; //flux rate between spectrum samples
ArrayList<Float> spectralFlux = new ArrayList<Float>();//hold all flux values

int threshold_window = 15; //how many samples to look nearby at when determining threshold
float multiplier = 1.5; //how much of a difference from the average a beat onset should be marked by
ArrayList<Float> threshold = new ArrayList<Float>(); //averages of flux values for finding onsets

ArrayList<Float> prunedFlux = new ArrayList<Float>(); //filtered flux values based on the threshold
ArrayList<Float> peaks = new ArrayList<Float>(); //filtered flux values from the pruning to isolate peaks

int spectraidx = 0; //current index chunk being played
int lastidx = 0; //last index chunk rendered for

float maxFlux = 0; //store highest flux value for ratio usage

int time = 0; //track milliseconds
int starttime = 0; //track beginning of play

/*********************
* Game Logic Related *
**********************/
color mybg; //store color value not really needed can be done dynamically quick
Ball myBall; //object to hold temporary instances when making new ball objects
ArrayList<Ball> myBalls = new ArrayList<Ball>(); //hold all the active ball objects
Ship myShip = new Ship();
int lastblue = 0; //previous blue value of background
int score = 0;
int hiscore = 0;
boolean running = false;
//Keep track of which arrow keys are down for ship movement
HashMap<String, Boolean> keysDown = new HashMap<String, Boolean>();

void setup() //run once
{
  frameRate(120); //if possible
  size(1280, 400, P3D); //window size
  minim = new Minim(this);//init audio lib 
  
}


//Open a file chooser dialog box and let the user pick an audio file
void selectFile(){
  JFileChooser chooser = new JFileChooser();
  chooser.setFileFilter(chooser.getAcceptAllFileFilter());
  int returnVal = chooser.showOpenDialog(null);
  if (returnVal == JFileChooser.APPROVE_OPTION) 
  {
   filename = chooser.getSelectedFile().getAbsolutePath(); 
  }
}

void startGame(){
  // specify that we want the audio buffers of the AudioPlayer
  // to be 1024 samples long because our FFT needs to have 
  // a power-of-two buffer size and this is a good size.
 
  jingle = minim.loadFile(filename, 1024);
  jingle2 = minim.loadSample(filename,1024);
 
  //visual environment
  mybg = color(0,0,0);//set black background
  background(mybg);//apply
  
  
  //Initialize everything
  spectralFlux.clear();
  threshold.clear();
  prunedFlux.clear();
  peaks.clear();
  myBalls.clear();
  score = 0;
  
  //analyze
  doAnalysis();
  running = true;
  time = millis(); //track time
  starttime = time; //start time
  jingle.play(); //begin playback
}

void draw() //called over and over
{
  
  background(mybg); //redraw background first
  
  //Show a title screen when the game is not running
  if(!running){
     if(score > hiscore)hiscore = score;  //move this
     mybg = color(0,0,0);
     fill(255);
     textSize(16);
     text("Press S to start", 8, 22);
     text("Press O to open an audio file to play", 8, 42);
     text("Use the arrow keys to avoid the obstacles.", 8, 62);
     text("High Score: "+hiscore, 8, 82);
     return; 
  }
  
  drawGraph(spectralFlux,color(0,255,255)); //draw the flux
  drawGraph(peaks,color(0,255,0)); //draw the flux
  drawGraph(threshold,color(255,255,255)); //draw the threshold
  time = millis() - starttime; //time since started playing
  spectraidx = int((time)/23.297);//convert to associated chunk index *****MAGIC NUMBER I WANT TO FIGURE OUT*******
  //println(spectraidx+","+spectras.length+","+peaks.size());
  if (spectraidx < spectras.length){ //if its in bounds
      stroke(color(255,0,0)); //draw with red
      float fluxY = (height*4/5) - 
        (spectralFlux.get(spectraidx)/maxFlux) * (height*3/5); //3/4 down screen, up ratio of flux as percentage of highest, up to top of window
      line(0,fluxY,width,fluxY); //make the instantaneous flux horizontal line across the screen
     
      stroke(color(255,255,0)); //yellow
      float timeX = spectraidx/float(spectras.length) * width; //percentage of index progress converted to percentage of window size

      line(timeX,0,timeX,height); //draw a vertical time bar
      
      stroke(255); //go back to white
      
      for(int i = lastidx+1; i <= spectraidx; i++) //go through the iterated range since last draw
      {
        if(peaks.get(i)>0){ //if there's a peak
          makeABall(peaks.get(i)/maxFlux * (height/10) + 5); //make a ball with size based on the intensity
          lastblue = int(min(255, lastblue + peaks.get(i)/maxFlux * 200 + 50)); //increase blue intensity of background
        }
        else{ //not a peak
          lastblue = max(0,lastblue -10); //decrease blue intensity
        }
      }
      //assign the background colour
      //blue based on beat, r/g based on relative amplitude
      mybg = color(64-amps[spectraidx]/2,amps[spectraidx],lastblue);  
    }else{
       //If the song is over and 5 seconds have passed, return to title screen
       if(millis() > jingle.length() + starttime + 5000){
         running = false;
       }
    }
   lastidx = spectraidx;//just done index point

   myShip.draw();

   textSize(20);
   fill(255,255,255);
   text("Score: "+score, 8, 22);

   doGame(); //update balls and ship movement
   
}

void makeABall(float size){//take a size and make a ball on the right of the screen
    if(size<6)return;
    size *= 3;
    myBall = new Ball(size);  
    myBall.setX(width);
    //myBall.setY(height/2+random(-height/2,height/2));
    myBall.setY(random(0, height));
    myBalls.add(myBall);
}

void doGame(){//move the balls

  int shipX = (int)myShip.getX();
  int shipY = (int)myShip.getY();
  int shipSize = (int)myShip.getSize();

  for(int y = myBalls.size()-1; y >= 0; y--){ //check all
     myBalls.get(y).left(); //move left
     if(myBalls.get(y).offscreen()){ //gone offscreen
       myBalls.remove(y); //get rid of it from the array
     }else{ //otherwise
       myBalls.get(y).draw(); //draw it on screen

       //check if any ball is touching the ship (testing at the corners of the ship triangle) and if the ships not already recovering from a previous collision
       if(  
             myShip.getRecoveryTime() == 0 
          &&(myBalls.get(y).isat(shipX, shipY)  
          || myBalls.get(y).isat(shipX+shipSize, shipY+shipSize/2)  
          || myBalls.get(y).isat(shipX, shipY +shipSize))
        ){
         
         
         score -= 500;                //Take a hit out of the score if the player hits a ball
         myShip.setRecoveryTime(50);  //Don't check for collisions for 50 cycles of the game loop
         
         //todo play a sound effect or soemthing?
       }
       
       //If the ship is in the midst of recovering from a collision, flash red background and fade it back out
       if(myShip.getRecoveryTime() > 0){
         mybg = color(myShip.getRecoveryTime()*5,0,0); //collision bg color assignment
       }
     }
   }
   
   
   //Determine where ship should be moving
   float dx = xMovement();
   float dy = yMovement();
   myShip.move(dx, dy);  //and move it!
   
   myShip.decrementRecoveryTime();
   
   score++;  //Increment score counter
}


//Determine which keys are being held related to the ships X movement and return -1 (left), 0 (stationary) or 1 (right)
float xMovement(){
  if(keysDown.containsKey("LEFT") && keysDown.get("LEFT") == true)return -1;
  if(keysDown.containsKey("RIGHT") && keysDown.get("RIGHT") == true)return 1;
  return 0;
}


//Determine which keys are being held  related to the ships Y direction
float yMovement(){
   if(keysDown.containsKey("UP") && keysDown.get("UP") == true)return -1;
  if(keysDown.containsKey("DOWN") && keysDown.get("DOWN") == true)return 1;
  return 0;
}

void  backToTitle(){
  running = false;
  jingle.pause(); 
}

void keyPressed(){
  if(key == CODED){

    if (keyCode == LEFT){
      keysDown.put("LEFT", true);
    }

    if(keyCode == RIGHT){
      keysDown.put("RIGHT", true);
    }
    
    if(keyCode == UP){
       keysDown.put("UP", true);
    }
    
    if(keyCode == DOWN){
      keysDown.put("DOWN", true);
    }
    
  }
  if (key == ESC && running == true){
      key=0;  //prevent default handler
      backToTitle();  //go to title
    }

  if(running == false){
    if(key == 's'){
      startGame();
    }
    if(key == 'o'){
      selectFile();
    }
  }
 
}

void keyReleased(){
  if(key == CODED){

    if (keyCode == LEFT){
      keysDown.put("LEFT", false);
    }

    if(keyCode == RIGHT){
      keysDown.put("RIGHT", false);
    }
    
    if(keyCode == UP){
       keysDown.put("UP", false);
    }
   
    if(keyCode == DOWN){
      keysDown.put("DOWN", false);
    }
    
  }
}


void doAnalysis(){
  //run all the calculations
  calcSpectras();
  calcFluxes();
  calcThresholds();
  calcPrunes();
  calcPeaks();
  calcAmps();
}

void calcSpectras(){
  //fill up a big array of all the spectra
  float[]  rightChannel = jingle2.getChannel(AudioSample.RIGHT); //copy the right channel
  float[]  leftChannel = jingle2.getChannel(AudioSample.LEFT); //copy the left channel
  
  //mono those two channels into one array (this may be not done fully correctly but couldn't find another way)
  for (int n = 0; n < rightChannel.length; n++){
    leftChannel[n] = leftChannel[n] + rightChannel[n];
  }
  
  int fftSpread = 1024;  //amount of samples used per fft
  float[] fftsamps = new float[fftSpread]; //make space to hold those samples
  fft = new FFT(fftSpread, jingle2.sampleRate()); //setup fft operator based on desired sampling rates
  
  int chunkCount = (leftChannel.length/fftSpread) + 1; //how many chunks the audio object will be broken into
  
  spectras = new float[chunkCount][fftSpread/2]; //make space for that many chunks of the desired number of samples (/2 because of nyquist)
  
  for(int idx = 0; idx < chunkCount; idx++){//process and assign every chunk
    int startpoint = idx * fftSpread; //don't increment by 1, by size of chunks instead
    int chunksize = min(leftChannel.length - startpoint, fftSpread); //this particular chunk may have to be shorter if at the end
    
    arraycopy(leftChannel, startpoint, fftsamps, 0, chunksize); //copy the sample data into the open fftsamplespace
    if (chunksize < fftSpread){ //if its the last cut smaller chunk
      Arrays.fill(fftsamps, chunksize, fftsamps.length-1, 0.0); //fill the extra space with 0s
    }
    
    fft.forward(fftsamps); //run an fft transform on those samples
    arraycopy(spectrum, 0, lastSpectrum, 0, spectrum.length); //copy the last run results into lastSpectrum
    for(int i = 0; i < 512; i++){ //go through every band of the transformed fft and save the values to the associated chunk slot
      spectras[idx][i] = fft.getBand(i);
      spectrum[i] = fft.getBand(i); //current spectrum
    }
    
    calcFluxes(); //add the new flux value
   
  }
}

void calcFluxes(){
  //fill up a big array of all the flux 
   flux = 0; //start with no flux changes
    for (int n = 0; n < spectrum.length; n++){ //go through the samples of the analyzed spectrum for this chunk
      float value = (spectrum[n] - lastSpectrum[n]); //get the difference between last chunk and this one
      flux += value < 0? 0: value; //add it to the flux if its positive
    }
    if (flux > maxFlux){ //if this is the new biggest flux value mark it
      maxFlux = flux;
    }
    spectralFlux.add(flux); //add to the arraylist of stored flux values (will be as many as there are chunks)
}

void calcThresholds(){
  //fill up a big array of all the thresholds
  for(int i = 0; i < spectralFlux.size(); i++){ //go through all the fluxes
    int start = max(0, i - threshold_window); //if youre at the beginning you can't check as far as 10 back
    int end = min(spectralFlux.size() - 1, i + threshold_window); //if youre at the end you cant check 10 forward
    float average = 0; //average starts at 0
    for (int j = start; j <= end; j++){ //go through the desired flux values
      average += spectralFlux.get(j); //add each value
    }
    average = average / (end - start); //get the mean
    threshold.add(average * multiplier); //multiply by ratio we marked the threshold as
  } 
}

void calcPrunes(){
  //fill an array with only the flux values exceeding the threshold
  for(int j = 0; j < threshold.size(); j++){ //iterate through
    if(threshold.get(j) <= spectralFlux.get(j)){ //if the threshold is below the value
      prunedFlux.add(spectralFlux.get(j) - threshold.get(j)); //keep it
    }
    else{ //otherwise replace with a 0
      prunedFlux.add(0.0);
    }
  }
}

void calcPeaks(){
  //fill an array with only the peaks of the pruned set
  peaks.add(0.0); //beginning cant be checked
  for( int i = 1; i < prunedFlux.size() - 1; i++ ) //go through the rest
  {
     if( prunedFlux.get(i) > prunedFlux.get(i+1) 
          && prunedFlux.get(i) > prunedFlux.get(i-1)){ //bigger than either side neighbour
        peaks.add( prunedFlux.get(i) ); //keep it
     }
     else{ //otherwise replace with 0
        peaks.add( 0.0 );        
     }
  }
  peaks.add(0.0); //end cant be checked
}

//this one just adds the spectras together and makes an array 
//holding the relative amplitudes from 0 to 255
void calcAmps(){
  amps = new float[spectras.length];
  float biggest = 0;
  for (int n = 0; n < spectras.length; n++){
    float temp = 0;
    for (int i = 0; i < spectras[n].length; i++){
      temp+= spectras[n][i];
    }
    amps[n] = temp;
    if (temp > biggest){
      biggest = temp;
    }
  }
  for (int n = 0; n < amps.length; n++){
    amps[n] = amps[n]/biggest * 128;
  }   
}

//plot a graph of floats
void drawGraph(ArrayList<Float> alf, color c){
  stroke(c);
  float w = alf.size();
  float prevY = height*3/4;
  float prevX = 0;
  for (int n = 0; n < w; n++){
    float newX = n/w * width;
    float newY = (height*4/5) - 
        (alf.get(n)/maxFlux) * (height*3/5);
    line(prevX,prevY,newX,newY);
    prevX = newX;
    prevY = newY;
  }
}
