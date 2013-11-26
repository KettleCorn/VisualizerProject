//Adapted and Modified from Daniel Shiffman's particle demo accompanying Processing 2.0
class ParticleSystem {
  ArrayList<Particle> particles;

  PShape particleShape;

  int red = 255;
  int grn = 255;
  int blu = 255;

  ParticleSystem(int n) {
    particles = new ArrayList<Particle>();
    particleShape = createShape(PShape.GROUP);

    for (int i = 0; i < n; i++) {
      Particle p = new Particle(red,grn,blu);
      particles.add(p);
      particleShape.addChild(p.getShape());
    }
  }

  void update() {
    for (Particle p : particles) {
      p.update();
    }
  }

  void setEmitter(float x, float y) {
    for (Particle p : particles) {
      if (p.isDead()) {
        p.rebirth(x, y, red, grn, blu);
      }
    }
  }

  void setRGB(int r, int g, int b){
    red = r;
    grn = g;
    blu = b;
  }

  void display() {

    shape(particleShape);
  }
}

