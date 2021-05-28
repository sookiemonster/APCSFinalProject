import java.util.*;

Window frame; //Setup the window
ArrayList<WindowObject> left = new ArrayList<WindowObject>(2);
ArrayList<WindowObject> right = new ArrayList<WindowObject>(8);
ArrayList<Interactable> elements = new ArrayList<Interactable>(2);
ArrayList<Slider> adjustments = new ArrayList<Slider>(2);

Interactable selectedElement;
boolean doOnce = false;
int load = 0;

PImage currentImage, edit;
Display preview, editPreview;

int frames = 0;
final int updateInterval = 2; 

Kernel s = new Kernel(new float[][] {{0, -1, 0},
                                     {-1, 3, 1},
                                     {0, -1, 0}});
PImage pSharp;
boolean isSharpening = false;
SharpnessSlider sharpen;

void setup() {
  size(1920, 1080);
  colorMode(HSB, 360, 100, 100); // Set the color mode to Hue (360 degrees), Saturation (0-100), Brightness (0-100)
  surface.setTitle("LiteRoom"); // Set the title of the window to "Processing Room"
  frame = new Window(); 
  
  elements.add(new Navigator(frame.getPadding(), 966, "Load Image", currentImage));
  elements.add(new Navigator(frame.getPadding(), 1005, "Save Image", currentImage));
  
  setupLeft();
  setupRight();
  spaceWindowObjects();
  
  drawAdjuster();
  
  spaceWindowObjects();
  
  drawWindowObjects();
  drawElements();
  
}

void draw() {
  frames++;
  
  frame.updateSize();
  frame.display();      
  drawWindowObjects();
  drawElements();
  
  if (currentImage != null) {
    if (load == 1) {
      pSharp = edit.copy();
      s.apply(edit, pSharp);
      load++;
    }
    
    if (edit == null) {
      edit = currentImage.copy();
      edit.loadPixels();
      load++;
    }
    
    if (selectedElement != null && frames > updateInterval) {
      frames = 0;
      edit = currentImage.copy();
      if (sharpen.getDiff() < 0) {
        edit.filter(BLUR, abs(sharpen.getDiff()));
        isSharpening = false;
      } else if (sharpen.getDiff() > 0) {
        isSharpening = true;
      } else {
        isSharpening = false;
      }
      edit.loadPixels();
      adjust();
    }
    editPreview = new Display(edit);
  }
  
  fill(0,0,100);
  textSize(20);
  textAlign(LEFT);
  text("FPS: "+ frameRate, 40, 60);
  
}


// Create Window Objects on the left side
void setupLeft() {
  float padding = frame.getPadding();
  left.add(new WindowObject(padding, padding, 200));
  left.add(new WindowObject(padding, 0, 100));
  left.add(new WindowObject(padding, 0, 100));
}

// Create Window Objects on the right side
void setupRight() {
  float rightX = frame.getSideBarWidth() + frame.getWidth() + frame.getPadding();
  right.add(new WindowObject(rightX, frame.getPadding(), 200, "Histogram"));
  right.add(new WindowObject(rightX, 0, 500, "Adjustments"));
  right.add(new WindowObject(rightX, 0, 100));
}

// Move Window Objects in relation to each other (subsequent objects are padding px below each other)
void spaceWindowObjects() {
  for (int i = 1; i < left.size(); i++) {
    left.get(i).setY(left.get(i - 1).getY() + left.get(i - 1).getHeight() + frame.getPadding());
  }
  for (int i = 1; i < right.size(); i++) {
    right.get(i).setY(right.get(i - 1).getY() + right.get(i - 1).getHeight() + frame.getPadding());
  }
}

// Displays the Window Objects
void drawWindowObjects() {
  for (WindowObject w : left) {
    w.display();
  }
  float rightX = frame.getSideBarWidth() + frame.getWidth() + frame.getPadding(); 
  for (WindowObject w : right) {
    if (w.getX() != rightX) { // If the window is resized & the right elements aren't in the right position, move them
      w.setX(rightX);
    }
    w.display();
  }
  if (currentImage != null) {
    if ((currentImage.height > 1080) || (currentImage.width > 1920-288-288)) {
      currentImage = preview.resize(currentImage);
    } 
    if (edit != null) {
      editPreview.display();
    } else {
      preview.display();
    }
  }
}

// What happens during file selection
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    String filename = "" + selection;
    if (filename.indexOf(".jpeg") != -1 || filename.indexOf(".jpg") != -1 || filename.indexOf(".tga") != -1 || filename.indexOf(".png") != -1) {
      preview = new Display(filename);
      currentImage = loadImage(filename);
    }
  }
}

// Draws all elements. If an element is being dragged, no other elements will be dragged.
void drawElements() {
  if (selectedElement != null) {
    selectedElement.drag();
  }
  for (Interactable n : elements) {
    if (n instanceof Navigator) {
      if (currentImage != null && ((Navigator)n).imgPresent() == false) {
        ((Navigator)n).storeImage(currentImage);
      }
      if (n.isPressed() && doOnce == false) { //<>//
        ((Navigator)n).buttonFunction(((Navigator)n).title(), currentImage);
        doOnce = true;
      }  //<>//
    }
   if (selectedElement == null && currentImage != null && n.drag()) {
      selectedElement = n;
    }
  n.display(); 
  }  
}
 //<>//
void mouseReleased() {
  for (Interactable n : elements) {
    n.clearMouse();
  }
  selectedElement = null;
  doOnce = false;
}

void adjust() {
  colorMode(RGB, 256, 256, 256);
  for (int i = 0; i < edit.pixels.length; i++) {
    if (isSharpening) {
      edit.pixels[i] =lerpColor(edit.pixels[i], pSharp.pixels[i], sharpen.getDiff());
    }
    for (Slider n : adjustments) {
      if (n.isChanged()) {
        if (!(n instanceof SharpnessSlider)) {
          edit.pixels[i] = n.apply(edit.pixels[i]);
        }
      }
    }
  }
  colorMode(HSB, 360, 100, 100);
}

void drawAdjuster() {
  WindowObject w = right.get(1);
  float containerY = w.getInteriorY();
  
  int spacing = 30;
  int counter = 0;
   
  adjustments.add(new BrightnessSlider(right.get(1).getX() + 100, containerY)); counter++;
  adjustments.add(new TemperatureSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  adjustments.add(new TintSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  adjustments.add(new LightnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing), "Highlights", 0.9, 1)); counter++;
  adjustments.add(new LightnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing), "Whites", .75, .9)); counter++;
  adjustments.add(new LightnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing), "Shadows", 0.25, .5)); counter++;
  adjustments.add(new LightnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing), "Blacks", 0.0, .25)); counter++;
  adjustments.add(new SaturationSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  adjustments.add(new SharpnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  sharpen = (SharpnessSlider)adjustments.get(adjustments.size() - 1);
  
  for (Slider n : adjustments) {
    elements.add(n);
  }
  
  w.setHeight((counter - 1) * (adjustments.get(0).getHeight() + spacing) + spacing / 2);
  
}
