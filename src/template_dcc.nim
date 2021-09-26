
import nimgl/[glfw, opengl]


type
  Color = tuple[r: float64, g: float64, b: float64, a: float64]


proc framebufferSizeProc(window: GLFWwindow, width: int32, height: int32
                        ) : void {.cdecl.} =
    # Resize Viewport
    glViewport(0, 0, width, height)


proc inputProc(window: GLFWWindow): void =
  # Close Window if Esc.
  if window.getKey(GLFWKey.ESCAPE) == GLFWPress:
    window.setWindowShouldClose(true)


proc main() =
  # Initialize GLFW
  assert glfwInit()
  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWResizable, GLFW_TRUE)


  # Declare Constants
  const
    window_width: int32 = 800
    window_height: int32 = 600
    window_title: cstring = "Template DCC"
    clear_color: Color = (0.68, 1.0, 0.34, 1.0)

  # Create and Initialize a Window.
  let window = block:
    let w: GLFWWindow =
      glfwCreateWindow(window_width, window_height, window_title)

    if w == nil:
      echo "Failed to create a GLFW window."
      glfwTerminate()
      quit(-1)

    w.makeContextCurrent()
  
    discard w.setFramebufferSizeCallback(framebufferSizeProc)
    w


  # Loads OpenGL. Implemented by nimgl, doesn't use GLAD.
  assert glInit()

  # Set the Dimensions of the Rendering Viewport
  glViewport(0, 0, window_width, window_height)

  # Run Game Loop
  while not window.windowShouldClose:
    # Run Frame
    block:
      inputProc(window) # Process Input

      # Set Background Color and Display
      glClearColor(clear_color.r, clear_color.g, clear_color.b, clear_color.a)
      glClear(GL_COLOR_BUFFER_BIT)
      window.swapBuffers()

      glfwPollEvents() # Process Events Sent from OS

  # Clean Up GLFW
  window.destroyWindow()
  glfwTerminate()


main()
