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
     ellipse(x,y,-size/2,-size);
   }
   void left(){
     x-=5;
   }
   void right(){
     x+=5;
   }
}
   
