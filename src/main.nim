
import nimgl/[glfw, opengl]


type Color = tuple[r, g, b, a: GLfloat]


proc framebufferSizeProc(window: GLFWwindow, width: int32, height: int32
                        ) : void {.cdecl.} =
  # Resize Viewport
  glViewport(0, 0, width, height)

proc inputProc(window: GLFWWindow): void =
  # Close Window if Esc.
  if window.getKey(GLFWKey.ESCAPE) == GLFWPress:
    window.setWindowShouldClose(true)


proc loadAndCompileShader(path: string, type_of_shader: GLenum): GLuint =
  # Read shader source code from File
  var source: cstring = readFile(path)

  # Load the shader into OpenGL
  let id = glCreateShader(type_of_shader)
  glShaderSource(id, 1'i32, addr(source), nil)

  # Compile the shader
  glCompileShader(id)

  # Report any Compilation Errors
  var success: GLint
  glGetShaderiv(id, GL_COMPILE_STATUS, addr(success))
  if success != ord(GL_TRUE):
    const log_size: int32 = 1024
    var log: array[log_size, char]
    glGetShaderInfoLog(id, log_size, nil, addr(log))

    let s: string =
      case type_of_shader
        of GL_VERTEX_SHADER: "VERTEX"
        of GL_FRAGMENT_SHADER: "FRAGMENT"
        else: "UNKNOWN"
    echo "ERROR::SHADER::" & s & "::COMPILATION_FAILED\n"
    echo cast[cstring](addr(log))
  
  id


type Mesh = tuple[vao, vbo, ebo: GLuint, vertices_length, indices_length: int]

proc loadMeshIntoOpenGL(vertices_address: pointer, vertices_length: int,
                        indices_address: pointer, indices_length: int): Mesh =
  assert vertices_length mod 3 == 0
  assert indices_length mod 3 == 0

  var mesh: Mesh = (0'u32, 0'u32, 0'u32, vertices_length, indices_length)

  glGenVertexArrays(1'i32, addr(mesh.vao))
  glGenBuffers(1'i32, addr(mesh.vbo))
  glGenBuffers(1'i32, addr(mesh.ebo))

  glBindVertexArray(mesh.vao)

  glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo)
  glBufferData(GL_ARRAY_BUFFER, vertices_length * sizeof(float32), vertices_address, GL_STATIC_DRAW)

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ebo)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices_length * sizeof(uint32), indices_address, GL_STATIC_DRAW)

  glVertexAttribPointer(0'u32, 3'i32, EGL_FLOAT, false, sizeof(GLfloat) * 3, nil)
  glEnableVertexAttribArray(0'u32)

  glBindBuffer(GL_ARRAY_BUFFER, 0'u32)
  glBindVertexArray(0'u32)

  mesh

proc drawTriangles(mesh: var Mesh) =
  glBindVertexArray(mesh.vao)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ebo)
  glDrawElements(GL_TRIANGLES, cast[GLsizei](mesh.indices_length), GL_UNSIGNED_INT, nil)

proc destroy(mesh: var Mesh) =
  glDeleteVertexArrays(1'i32, addr(mesh.vao))
  glDeleteBuffers(1'i32, addr(mesh.vbo))


proc main() =
  # Declare Constants
  const
    window_width: int32 = 800
    window_height: int32 = 600
    window_title: cstring = "Template DCC"
    clear_color: Color = (0.68'f32, 1.0'f32, 0.34'f32, 1.0'f32)
    vertex_shader_path: string = "shaders/default.vs"
    fragment_shader_path: string = "shaders/default.fs"


  # Initialize GLFW
  block:
    assert glfwInit()
    glfwWindowHint(GLFWContextVersionMajor, 3'i32)
    glfwWindowHint(GLFWContextVersionMinor, 3'i32)
    glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
    glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
    glfwWindowHint(GLFWResizable, GLFW_TRUE)


  # Create and Initialize a Window
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


  # Load OpenGL. Implemented by nimgl, doesn't use GLAD.
  assert glInit()


  # Load, Compile, and Link the Vertex and Fragment Shaders
  let po = block:
    # Load and Compile Shaders
    let vso = loadAndCompileShader(vertex_shader_path, GL_VERTEX_SHADER)
    let fso = loadAndCompileShader(fragment_shader_path, GL_FRAGMENT_SHADER)

    # Link the Shader Objects
    let po = glCreateProgram()
    glAttachShader(po, vso)
    glAttachShader(po, fso)
    glLinkProgram(po)

    # Report any Linking Errors
    var success: GLint
    glGetProgramiv(po, GL_LINK_STATUS, addr(success))
    if success != ord(GL_TRUE):
      const log_size: int32 = 1024
      var log: array[log_size, char]
      glGetProgramInfoLog(po, log_size, nil, addr(log))

      echo "ERROR::SHADER::PROGRAM::LINKING_FAILED\n"
      echo cast[cstring](addr(log))

    # Delete the Shader Objects
    glDeleteShader(vso)
    glDeleteShader(fso)
    po


  # Set Up Vertex Data
  var mesh = block:
    var
      vertices = [
         0.5'f32,  0.5'f32, 0.0'f32,
         0.5'f32, -0.5'f32, 0.0'f32,
        -0.5'f32, -0.5'f32, 0.0'f32,
        -0.5'f32,  0.5'f32, 0.0'f32
      ]
      indices = [
        0'u32, 1'u32, 3'u32,
        1'u32, 2'u32, 3'u32
      ]
    loadMeshIntoOpenGL(addr(vertices), len(vertices), addr(indices), len(indices))


  # Run Game Loop
  while not window.windowShouldClose:
    # Run Frame
    block:
      inputProc(window) # Process Input

      # Set Background Color and Display
      glClearColor(clear_color.r, clear_color.g, clear_color.b, clear_color.a)
      glClear(GL_COLOR_BUFFER_BIT)

      glUseProgram(po)
      mesh.drawTriangles()

      window.swapBuffers()

      glfwPollEvents() # Process Events Sent from OS

  # Clean Up OpenGL
  mesh.destroy()
  glDeleteProgram(po)

  # Clean Up GLFW
  window.destroyWindow()
  glfwTerminate()


main()
