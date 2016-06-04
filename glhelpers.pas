unit glhelpers;

{$mode objfpc}{$H+}
//{$define RENDERDOC}

interface

uses
  Classes, SysUtils, dglOpenGL;

type

  { TGLBuffer }

  TGLBuffer = class
  private
    fBufferHandle: GLHandle;
  public
    constructor Create(Data: pointer; size: GLuint; flags: GLbitfield = 0);
    destructor Destroy; override;
    procedure Bind(target: GLenum);
    procedure Bind(target: GLenum; index: Gluint);
    property Handle: GLHandle read fBufferHandle;
  end;

  { TShader }

  TShader = class
  public
    constructor Create(shaderType: GLenum; const src: string);
    constructor CreateFromFile(shaderType: GLenum; const filename: string);
    destructor Destroy; override;
  private
    fShaderHandle: GLHandle;
  end;

  { TRenderProgram }

  TRenderProgram = class
  public
    constructor Create(shaders: array of TShader);
    destructor Destroy; override;
    procedure Use;
    procedure SetUniformBlock(Name: string; buf: TGLBuffer);
  private
    fProgramHandle: GLHandle;
  end;

  { TVertexArray }

  TVertexArray = class
  private
    fHandle: GLHandle;
  public
    constructor Create;
    destructor Destroy; override;
    procedure EnableAttrib(Index: Gluint);
    procedure AttribFormat(Index: Gluint; Size: Glint; _Type: GLenum;
      Normalized: GLboolean; Offset: Gluint = 0);
    procedure VertexBuffer(Index: Gluint; Buf: TGLBuffer;
      Stride: Gluint; Offset: Gluint = 0);
    procedure IndexBuffer(Buf: TGLBuffer);
    procedure Bind;
    procedure Unbind;
    property Handle: GLHandle read fHandle;
  end;

// *****************************************************************************

implementation

uses
  Windows;

{ TVertexArray }

constructor TVertexArray.Create;
begin
  glCreateVertexArrays(1, @fHandle);
end;

destructor TVertexArray.Destroy;
begin
  glDeleteVertexArrays(1, @fHandle);
end;

procedure TVertexArray.EnableAttrib(Index: Gluint);
begin
  glEnableVertexArrayAttrib(fHandle, Index);
end;

procedure TVertexArray.AttribFormat(Index: Gluint; Size: Glint;
  _Type: GLenum; Normalized: GLboolean; Offset: Gluint);
begin
  glVertexArrayAttribFormat(fHandle, Index, Size, _Type, Normalized, Offset);
end;

procedure TVertexArray.VertexBuffer(Index: Gluint; Buf: TGLBuffer;
  Stride: Gluint; Offset: Gluint);
begin
  glVertexArrayVertexBuffer(fHandle, Index, Buf.Handle, Offset, Stride);
end;

procedure TVertexArray.IndexBuffer(Buf: TGLBuffer);
begin
{$IFDEF RENDERDOC}
  Bind;
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Buf.Handle);
  Unbind;
{$ELSE}
  glVertexArrayElementBuffer(fHandle, Buf.Handle);
{$ENDIF}
end;

procedure TVertexArray.Bind;
begin
  glBindVertexArray(fHandle);
end;

procedure TVertexArray.Unbind;
begin
  glBindVertexArray(GL_NONE);
end;

{ TGLBuffer }

constructor TGLBuffer.Create(Data: pointer; size: GLuint; flags: GLbitfield);
begin
  glCreateBuffers(1, @fBufferHandle);
  glNamedBufferStorage(fBufferHandle, size, Data, flags);
end;

destructor TGLBuffer.Destroy;
begin
  inherited Destroy;
  glDeleteBuffers(1, @fBufferHandle);
end;

procedure TGLBuffer.Bind(target: GLenum);
begin
  glBindBuffer(target, Handle);
end;

procedure TGLBuffer.Bind(target: GLenum; index: Gluint);
begin
  glBindBufferBase(target, index, Handle);
end;

{ TShader }

constructor TShader.Create(shaderType: GLenum; const src: string);
var
  compileStatus:        GLint;
  compilationLogLength: GLint;
  compilationLog:       string;
begin
  fShaderHandle := glCreateShader(shaderType);
  glShaderSource(fShaderHandle, 1, @src, nil);
  glCompileShader(fShaderHandle);
  glGetShaderiv(fShaderHandle, GL_COMPILE_STATUS, @compileStatus);
  if compileStatus <> 0 then
    OutputDebugString(PChar(Format('%s', ['compile ok'])))
  else
  begin
    OutputDebugString(PChar(Format('%s', ['compile failed'])));
    glGetShaderiv(fShaderHandle, GL_INFO_LOG_LENGTH, @compilationLogLength);
    SetLength(compilationLog, compilationLogLength);
    glGetShaderInfoLog(fShaderHandle, compilationLogLength,
      @compilationLogLength, PChar(compilationLog));
    OutputDebugString(PChar(compilationLog));
  end;
end;

constructor TShader.CreateFromFile(shaderType: GLenum; const filename: string);
var
  sourceFile:   TFileStream;
  sourceString: string;
begin
  try
    sourceFile := TFileStream.Create(filename, fmOpenRead);
    SetLength(sourceString, sourceFile.Size);
    sourceFile.Read(PChar(sourceString)^, sourceFile.Size);
  finally
    sourceFile.Free;
  end;
  Create(shaderType, sourceString);
end;

destructor TShader.Destroy;
begin
  inherited Destroy;
  glDeleteShader(fShaderHandle);
end;

{ TRenderProgram }

constructor TRenderProgram.Create(shaders: array of TShader);
var
  i: longword;
begin
  fProgramHandle := glCreateProgram();
  for i := Low(shaders) to High(shaders) do
  begin
    glAttachShader(fProgramHandle, shaders[i].fShaderHandle);
  end;
  glLinkProgram(fProgramHandle);
end;

destructor TRenderProgram.Destroy;
begin
  inherited Destroy;
  glDeleteProgram(fProgramHandle);
end;

procedure TRenderProgram.Use;
begin
  glUseProgram(fProgramHandle);
end;

procedure TRenderProgram.SetUniformBlock(Name: string; buf: TGLBuffer);
var
  idx: GLuint;
begin
  idx := glGetUniformBlockIndex(fProgramHandle, PChar(Name));
  if idx <> GL_INVALID_INDEX then
    buf.Bind(GL_UNIFORM_BUFFER, idx)
  else
    OutputDebugString('invalid uniform name');
end;

end.
