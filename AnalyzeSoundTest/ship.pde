class Ship{
  private float x;
  private float y;
  //private float dx;
  //private float dy;
  private float size;
  private float speed;
  private int recoveryTime;
  
  Ship(){
    size = 30; 
    speed = 4;
    y = 160;
    x = 40;
  }
  
  void setX(float p){
    x = p;
  }
  void setY(float p){
    y = p;
  }
  
  float getX(){
    return x;
  }
  
  float getY(){
    return y;
  }
  
  void setRecoveryTime(int t){
    recoveryTime = max(t, 0);
  }
  
  void decrementRecoveryTime(){
    if(recoveryTime > 0)recoveryTime--; 
  }
  
  int getRecoveryTime(){
    return recoveryTime;
  }
  
  
  float getSize(){
    return size;
  }
  
  void move(float dx, float dy){
    x+=dx * speed;
    y+=dy * speed; 
    
    if(x < 0)x = 0;
    if(x > width - size) x = width - size;
    
    if(y < 0)y = 0;
    if(y > height - size) y = height - size;
    
  }
  
   void draw(){
     stroke(255);
     fill(225);
     triangle(x,y,x+size,y+size/2,x,y+size);
   }
  
}
