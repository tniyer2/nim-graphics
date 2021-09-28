
import nimgl/[glfw, opengl]
import glm/[vec, mat, mat_transform]


type Color = tuple[r, g, b, a: GLfloat]


var
  window_width: int32 = 800
  window_height: int32 = 600

proc framebufferSizeProc(window: GLFWwindow, width: int32, height: int32
                        ) : void {.cdecl.} =
  window_width = width
  window_height = height
  # Resize Viewport
  glViewport(0, 0, width, height)

proc inputProc(window: GLFWWindow): void =
  # Close Window if Esc.
  if window.getKey(GLFWKey.ESCAPE) == GLFWPress:
    window.setWindowShouldClose(true)


type ShaderProgram = tuple[id: GLuint]

# Load and Compile a Shader
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

# Load, Compile, and Link the Vertex and Fragment Shaders
proc createShaderProgram(vertex_shader_path: string, fragment_shader_path: string): ShaderProgram =
  # Load and Compile Shaders
  let vso = loadAndCompileShader(vertex_shader_path, GL_VERTEX_SHADER)
  let fso = loadAndCompileShader(fragment_shader_path, GL_FRAGMENT_SHADER)

  # Create the Shader Program
  let program: ShaderProgram = (id: glCreateProgram())

  # Link the Shader Objects
  glAttachShader(program.id, vso)
  glAttachShader(program.id, fso)
  glLinkProgram(program.id)

  # Report any Linking Errors
  var success: GLint
  glGetProgramiv(program.id, GL_LINK_STATUS, addr(success))
  if success != ord(GL_TRUE):
    const log_size: int32 = 1024
    var log: array[log_size, char]
    glGetProgramInfoLog(program.id, log_size, nil, addr(log))

    echo "ERROR::SHADER::PROGRAM::LINKING_FAILED\n"
    echo cast[cstring](addr(log))

  # Delete the Shader Objects (no longer needed)
  glDeleteShader(vso)
  glDeleteShader(fso)

  program

proc use(program: var ShaderProgram): void =
  glUseProgram(program.id)

proc destroy(program: var ShaderProgram): void =
  glDeleteProgram(program.id)

proc setMat4Uniform(program: var ShaderProgram, uniform_name: cstring, matrix: Mat4): void =
  var matrix = matrix
  let location: int32 = glGetUniformLocation(program.id, uniform_name)
  glUniformMatrix4fv(location, 1'i32, false, caddr(matrix))


type Mesh = tuple[vao, vbo, ebo: GLuint, vertices_length, indices_length: int, uses_indices: bool, transform: Mat4f]

proc loadMeshIntoOpenGL(vertices_address: pointer, vertices_length: int,
                        indices_address: pointer, indices_length: int): Mesh =
  assert vertices_length mod 3 == 0
  assert indices_address == nil or indices_length mod 3 == 0

  var mesh: Mesh = (0'u32, 0'u32, 0'u32, vertices_length, indices_length, indices_address != nil, mat4f(1.0f))

  glGenVertexArrays(1'i32, addr(mesh.vao))
  glGenBuffers(1'i32, addr(mesh.vbo))
  if mesh.uses_indices:
    glGenBuffers(1'i32, addr(mesh.ebo))

  glBindVertexArray(mesh.vao)

  glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo)
  glBufferData(GL_ARRAY_BUFFER, vertices_length * sizeof(float32), vertices_address, GL_STATIC_DRAW)

  if mesh.uses_indices:
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ebo)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices_length * sizeof(uint32), indices_address, GL_STATIC_DRAW)

  glVertexAttribPointer(0'u32, 3'i32, EGL_FLOAT, false, sizeof(GLfloat) * 3, nil)
  glEnableVertexAttribArray(0'u32)

  glBindBuffer(GL_ARRAY_BUFFER, 0'u32)
  glBindVertexArray(0'u32)

  mesh

proc drawTriangles(mesh: var Mesh) =
  glBindVertexArray(mesh.vao)
  if mesh.uses_indices:
    glDrawElements(GL_TRIANGLES, cast[GLsizei](mesh.indices_length), GL_UNSIGNED_INT, nil)
  else:
    glDrawArrays(GL_TRIANGLES, 0'i32, cast[GLsizei](mesh.vertices_length div 3'i32))

proc destroy(mesh: var Mesh) =
  glDeleteVertexArrays(1'i32, addr(mesh.vao))
  glDeleteBuffers(1'i32, addr(mesh.vbo))
  if mesh.uses_indices:
    glDeleteBuffers(1'i32, addr(mesh.ebo))


proc main() =
  # Declare Constants
  const
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


  # Create a Shader Program
  var shaderProgram = createShaderProgram(vertex_shader_path, fragment_shader_path)


  # Set Up Vertex Data
  var mesh = block:
    var
      vertices = [
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f, -0.5f,
         0.5f, -0.5f, -0.5f,
         0.5f,  0.5f, -0.5f,
         0.5f,  0.5f, -0.5f,
        -0.5f,  0.5f, -0.5f,

        -0.5f, -0.5f,  0.5f,
         0.5f, -0.5f,  0.5f, 
         0.5f,  0.5f,  0.5f, 
         0.5f,  0.5f,  0.5f, 
        -0.5f,  0.5f,  0.5f,
        -0.5f, -0.5f,  0.5f,

        -0.5f,  0.5f,  0.5f,
        -0.5f,  0.5f, -0.5f,
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f,  0.5f,
        -0.5f,  0.5f,  0.5f,

        0.5f,  0.5f,  0.5f,
        0.5f,  0.5f, -0.5f,
        0.5f, -0.5f, -0.5f,
        0.5f, -0.5f, -0.5f,
        0.5f, -0.5f,  0.5f,
        0.5f,  0.5f,  0.5f,

        -0.5f, -0.5f, -0.5f,
         0.5f, -0.5f, -0.5f,
         0.5f, -0.5f,  0.5f,
         0.5f, -0.5f,  0.5f,
        -0.5f, -0.5f,  0.5f,
        -0.5f, -0.5f, -0.5f,

        -0.5f,  0.5f, -0.5f, 
         0.5f,  0.5f, -0.5f, 
         0.5f,  0.5f,  0.5f, 
         0.5f,  0.5f,  0.5f, 
        -0.5f,  0.5f,  0.5f, 
        -0.5f,  0.5f, -0.5f,
      ]
    loadMeshIntoOpenGL(addr(vertices), len(vertices), nil, 0)


  # Run Game Loop
  while not window.windowShouldClose:
    # Run Frame
    block:
      inputProc(window) # Process Input

      # Set Background Color and Display
      glClearColor(clear_color.r, clear_color.g, clear_color.b, clear_color.a)
      glClear(GL_COLOR_BUFFER_BIT)

      # Set Up Projection and View Transforms
      let proj = perspective(
        radians(45.0f),
        window_width / window_height,
        0.1f, 100.0f)
      let view = mat4f(1.0f)
        .translate(vec3(0f, 0f, -5.0f))
        .rotate(radians(45.0f), vec3(1.0f, 1.0f, 1.0f))

      shaderProgram.use()
      shaderProgram.setMat4Uniform("projection", proj)
      shaderProgram.setMat4Uniform("view", view)
      shaderProgram.setMat4Uniform("model", mesh.transform)
      mesh.drawTriangles()

      window.swapBuffers()

      glfwPollEvents() # Process Events Sent from OS

  # Clean Up OpenGL
  mesh.destroy()
  shaderProgram.destroy()

  # Clean Up GLFW
  window.destroyWindow()
  glfwTerminate()


main()
