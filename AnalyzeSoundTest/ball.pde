class Ball{
  private float size;
  private float x;
  private float y;
  
  Ball(int s){
    size = s; 
  }
  
  void setX(float p){
    x = p;
  }
  void setY(float p){
    y = p;
  }
   void draw(){
     stroke(255);
     fill(180);
     ellipse(x,y,-size,-size);
   }
   void left(){
     x-=5;
   }
   void right(){
     x+=5;
   }
   boolean offscreen(){
     if (x < 0){
       return true;
     }
     return false;
   }
   boolean isat(int xpos, int ypos){
     if(sqrt(pow(xpos-x,2)+(pow(ypos-y,2))) < size/2){
       return true;
     }
     return false;
   }
}
   
