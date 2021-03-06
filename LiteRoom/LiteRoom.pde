import java.util.*;

Window frame; //Setup the window
ArrayList<WindowObject> left = new ArrayList<WindowObject>(2);
ArrayList<WindowObject> right = new ArrayList<WindowObject>(8);
ArrayList<Interactable> elements = new ArrayList<Interactable>(2);
ArrayList<Slider> adjustments = new ArrayList<Slider>(2);

HSBContainer HSBObject;
VignetteContainer VignetteObject;

Interactable selectedElement;
boolean doOnce = false, createZoom = false, toZoom = true;
int load = 0;

PImage currentImage, edit, midstate, editstate, save;
Display preview, editPreview;

int frames = 0;
boolean changed = false;
final int updateInterval = 1; 

Kernel s = new Kernel(new float[][] {{0, -1, 0},
                                     {-1, 3, 1},
                                     {0, -1, 0}});
PImage pSharp;
boolean isSharpening = false;
SharpnessSlider sharpen; 

HashMap<Float, Integer> histogram;
HashMap<Float, Integer> reds;
HashMap<Float, Integer> blues;
HashMap<Float, Integer> greens;
Histogram colorGraph;

VRSlider round;

void setup() {
  size(1920, 1080);
  colorMode(HSB, 360, 100, 100); // Set the color mode to Hue (360 degrees), Saturation (0-100), Brightness (0-100)
  surface.setTitle("LiteRoom"); // Set the title of the window to "Processing Room"
  frame = new Window(); 
  
  elements.add(new Navigator(frame.getPadding(), 966, "Load Image", currentImage));
  elements.add(new Navigator(frame.getPadding(), 1005, "Save Image", currentImage));
  elements.add(new Navigator(1920 - frame.getSideBarWidth() + frame.getPadding(), 1005, "Clear Image"));
  elements.add(new Navigator(11, 11, 267, 199, "Zoom Box"));
  elements.add(new Navigator(frame.getPadding(), 888, "Reset Zoom"));
  
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
    if ((currentImage.height > 1054) || (currentImage.width > 1920 - (2 * frame.getSideBarWidth()))) {
      currentImage = preview.resize(currentImage);
    }
    
     if (edit == null) {
      edit = currentImage.copy();
      edit.loadPixels();
      load++;
    }
    
    if (load == 1 || pSharp == null ) {
      pSharp = edit.copy();
      s.apply(edit, pSharp);
      load++;
    }
    
    
    if (changed || (selectedElement != null && frames > updateInterval)) {
      for (Slider n : adjustments) {
        n.update();
      }
      
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
      checkPixels();
      edit.loadPixels();
      adjust();
      changed = false;
    }
    editPreview = new Display(edit);
  }
  
}


// Create Window Objects on the left side
void setupLeft() {
  float padding = frame.getPadding();
  left.add(new WindowObject(padding, padding, 200));
}

// Create Window Objects on the right side
void setupRight() {
  float rightX = frame.getSideBarWidth() + frame.getWidth() + frame.getPadding();
  right.add(new WindowObject(rightX, frame.getPadding(), 200, "Histogram"));
  right.add(new WindowObject(rightX, 0, 500, "Adjustments"));
  
  HSBObject = new HSBContainer(rightX, 0);
  right.add(HSBObject);
  
  VignetteObject = new VignetteContainer(rightX, 0);
  right.add(VignetteObject);
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
    if (w.getX() != rightX) { 
      w.setX(rightX);
    }
    w.display();
  }
  if (currentImage != null) {
    if ((currentImage.height > 1054) || (currentImage.width > 1920-288-288)) {
      currentImage = preview.resize(currentImage);
    }
    if (edit != null) {
      editstate = edit.copy();
      midstate = edit.copy();
      if (editstate.width > 267) {
        editstate.resize(267,0);
      }
      if (editstate.height > 199) {
        editstate.resize(0,199);
      }
      float smallX = 11 + ((267 - editstate.width)/2);
      float smallY = 11 + ((199 - editstate.height)/2);
      for (Interactable nav: elements) {
        if (nav instanceof Navigator) {
          ((Navigator)nav).setZoom(editstate, smallX, smallY, currentImage.width, currentImage.height, toZoom);
          ((Navigator)nav).addEditImage(midstate);
          if (((Navigator)nav).title().equals("Zoom Box")) {
            if (createZoom == false) {
              ((Navigator)nav).newZoom(smallX, smallY, editstate.width, editstate.height);
              createZoom = true;
            }
          }
        }
      }
      image(editstate, smallX, smallY);
      image(midstate, preview.canvasX(), preview.canvasY());
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
      for (Interactable nav: elements) {
        if (nav instanceof Navigator) {
          ((Navigator)nav).setImage(currentImage);
        }
      }
    histogram = new HashMap<Float, Integer>();
    reds = new HashMap<Float, Integer>();
    blues = new HashMap<Float, Integer>();
    greens = new HashMap<Float, Integer>();
    for (int i = 0; i < currentImage.pixels.length; i++) {
      float red = red(currentImage.pixels[i]);
      float blue = blue(currentImage.pixels[i]);
      float green = green(currentImage.pixels[i]);
      float light = lightness(red, green, blue);
      if (!histogram.containsKey(light)) {
         histogram.put(light, 1);
       } else {
         int count = histogram.get(light);
         histogram.replace(light, ++count); 
       }    
      if (!reds.containsKey(convertRed(red))) {
         reds.put(convertRed(red), 1);
       } else {
         int count = reds.get(convertRed(red));
         reds.replace(convertRed(red), ++count); 
       }
      if (!blues.containsKey(convertBlue(blue))) {
         blues.put(convertBlue(blue), 1);
       } else {
         int count = blues.get(convertBlue(blue));
         blues.replace(convertBlue(blue), ++count); 
       }
      if (!greens.containsKey(convertGreen(green))) {
         greens.put(convertGreen(green), 1);
       } else {
         int count = greens.get(convertGreen(green));
         greens.replace(convertGreen(green), ++count); 
       }
      }
     colorGraph = new Histogram(histogram, reds, blues, greens);
    }
  }
}

float convertRed(float r) {
  float convert = Math.round(((r % 255) / 255) * 100);
  convert = convert / 100;
  return convert;
}

float convertBlue(float b) {
  float convert = Math.round(((b % 255) / 255) * 100);
  convert = convert / 100;
  return convert;
}

float convertGreen(float g) {
  float convert = Math.round(((g % 255) / 255) * 100);
  convert = convert / 100;
  return convert;
}

// Draws all elements. If an element is being dragged, no other elements will be dragged.
void drawElements() {
  if (selectedElement != null) {
    selectedElement.drag();
  }
  if (colorGraph != null) {
    colorGraph.display();    
  } else {
    colorGraph = new Histogram();
  }
  for (Interactable n : elements) {
    if (n instanceof Navigator) {
      if (currentImage != null && ((Navigator)n).imgPresent() == false) {
        ((Navigator)n).setImage(currentImage);
      }
      if (n.isPressed() && doOnce == false) {
        ((Navigator)n).buttonFunction(((Navigator)n).title(), currentImage);
        if (((Navigator)n).title().equals("Clear Image")) {
          currentImage = null;
          save = null;
          edit = null;
          midstate = null;
          editstate = null;
          preview.clear();
          editPreview.clear();
          pSharp = null;
          clearAdjustments();
          histogram.clear();
          reds.clear();
          blues.clear();
          colorGraph.clear();
          for (Interactable nav: elements) {
            if (nav instanceof Navigator) {
              ((Navigator)nav).clear();
            }
          }
        } 
        if (((Navigator)n).title().equals("Reset Zoom")) {
            for (Interactable nav: elements) {
              if (nav instanceof Navigator) {
                ((Navigator)nav).clearZoom();
              }
            } //<>//
          }
          createZoom = false;
        doOnce = true;
      }   //<>//
    }
   if (selectedElement == null && currentImage != null && n.drag()) {
      selectedElement = n;
      changed = true; //<>//
    }
  n.display(); 
  }  
}

public void mouseClicked(MouseEvent evt) {
  if (evt.getCount() == 2) {
    doubleClicked();
  }
}

void doubleClicked() {
  for (Slider n : adjustments) {
    if (n.onSlider(mouseX, mouseY)) {
      n.clear();
      n.update();
    }
  }
  changed = true;
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
  histogram = new HashMap<Float, Integer>();
  reds = new HashMap<Float, Integer>();
  blues = new HashMap<Float, Integer>();
  greens = new HashMap<Float, Integer>();
  for (int i = 0; i < edit.pixels.length; i++) {
    if (isSharpening) {
      colorMode(RGB, 256, 256, 256);
      edit.pixels[i] = lerpColor(edit.pixels[i], pSharp.pixels[i], map(sharpen.getDiff(), 0, 2, 0, 1));
    }   
    for (Slider n : adjustments) {
      if (n.isChanged()) {
        if (n instanceof VBSlider) {
          VBSlider b = (VBSlider)n;
          edit.pixels[i] = b.apply(i, edit.pixels[i], edit.width, edit.height, round.getRoundness());
        } else if (!(n instanceof SharpnessSlider)) {
          edit.pixels[i] = n.apply(edit.pixels[i]);
        } 
      }
    }
    float red = red(edit.pixels[i]);
    float blue = blue(edit.pixels[i]);
    float green = green(edit.pixels[i]);
    float light = lightness(red, blue, green);
     if (!histogram.containsKey(light)) {
       histogram.put(light, 1);
     } else {
       int count = histogram.get(light);
       histogram.replace(light, ++count); 
     }   
    if (!reds.containsKey(convertRed(red))) {
       reds.put(convertRed(red), 1);
     } else {
       int count = reds.get(convertRed(red));
       reds.replace(convertRed(red), ++count); 
     }
    if (!blues.containsKey(convertBlue(blue))) {
         blues.put(convertBlue(blue), 1);
     } else {
       int count = blues.get(convertBlue(blue));
       blues.replace(convertBlue(blue), ++count); 
     }
     if (!greens.containsKey(convertGreen(green))) {
       greens.put(convertGreen(green), 1);
     } else {
       int count = greens.get(convertGreen(green));
       greens.replace(convertGreen(green), ++count); 
     }
  }
  colorGraph = new Histogram(histogram, reds, blues, greens);
  colorMode(HSB, 360, 100, 100); 
}

PImage adjustImage(PImage p) {
  PImage img = p.copy();
  PImage imgSharp = img.copy();
  img.loadPixels();
  
  if (isSharpening) {
    s.apply(img, imgSharp);
  } else if (sharpen.getDiff() < 0) {
    img.filter(BLUR, map(abs(sharpen.getDiff()), 0, 2, 0, max(img.width / 1344, img.height / 1054)  + 2));
  }
   
  for (int i = 0; i < img.pixels.length; i++) {
    if (isSharpening) {
      colorMode(RGB, 256, 256, 256);
      img.pixels[i] = lerpColor(img.pixels[i], imgSharp.pixels[i], map(sharpen.getDiff(), 0, 2, 0, 1));
    }   
    for (Slider n : adjustments) {
      if (n.isChanged()) {
        if (n instanceof VBSlider) {
          VBSlider b = (VBSlider)n;
          img.pixels[i] = b.apply(i, img.pixels[i], img.width, img.height, round.getRoundness());
        } else if (!(n instanceof SharpnessSlider)) {
          img.pixels[i] = n.apply(img.pixels[i]);
        } 
      }
    }
  }
  colorMode(HSB, 360, 100, 100);
  
  return img;
}

float lightness(float r, float g, float b) {
  float nR = r / 255;
  float nG = g / 255;
  float nB = b / 255;
  float x = (Math.round(((max(nR, nG, nB) + min(nR, nG, nB)) / 2.0) * 100));
  x = x/100;
  return x; 
}

void drawAdjuster() {
  WindowObject w = right.get(1);
  float containerY = w.getInteriorY();
  
  int spacing = 30;
  float counter = 0;
   
  adjustments.add(new BrightnessSlider(right.get(1).getX() + 100, containerY)); counter++;
  adjustments.add(new ContrastSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  adjustments.add(new TemperatureSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  adjustments.add(new TintSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  adjustments.add(new LightnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing), "Highlights", 0.9, 1)); counter++;
  adjustments.add(new LightnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing), "Whites", .75, .9)); counter++;
  adjustments.add(new LightnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing), "Shadows", 0.25, .5)); counter++;
  adjustments.add(new LightnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing), "Blacks", 0.0, .25)); counter++;
  adjustments.add(new SaturationSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  adjustments.add(new VibranceSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter++;
  adjustments.add(new SharpnessSlider(right.get(1).getX() + 100, containerY + (counter * spacing))); counter+=.2;
  sharpen = (SharpnessSlider)adjustments.get(adjustments.size() - 1);
   
  for (Slider[] arr : HSBObject.sliders) {
    for (Slider n : arr) {
      adjustments.add(n);
    }
  }
  
  for (Slider n : VignetteObject.sliders) {
    adjustments.add(n);
    if (n instanceof VRSlider) {
      round = (VRSlider)n;
    }
  }
  
  for (Slider n : adjustments) {
    elements.add(n);
  }
  
  w.setHeight((counter - 1) * (adjustments.get(0).getHeight() + spacing) + spacing / 2);
  
}

void clearAdjustments() {
  for (Slider n : adjustments) {
    n.clear();
  }
}

void checkPixels() {
  if (edit.pixels.length != pSharp.pixels.length) {
    pSharp = edit.copy();
    s.apply(edit, pSharp);
  }
}
