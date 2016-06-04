unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, OpenGLContext, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, matrix, dglOpenGL, glhelpers;

type
  TransformBlock = record
    matrix: Tmatrix4_single;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    OpenGLControl1: TOpenGLControl;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OpenGLControl1Paint(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
    fProgram: TRenderProgram;
    fVtxBuf:  TGLBuffer;
    fIdxBuf:  TGLBuffer;
    fUniBuf:  TGLBuffer;
    fVAO:     TVertexArray;
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
const
  vertices:  array [0..8] of GLfloat = (-0.5, -0.5, 0.0,  0.5, -0.5, 0.0, 0.5, 0.5, 0.0);
  indices:  array [0..2] of GLushort = (0, 1, 2);
var
  shaders:   array [0..1] of TShader;
  shader:    TShader;
  transform: TransformBlock;
begin
  OpenGLControl1.DebugContext := True;
  InitOpenGL();
  OpenGLControl1.MakeCurrent;
  ReadImplementationProperties;
  ReadExtensions;
  transform.matrix.init_identity;
  try
    shaders[0] := TShader.CreateFromFile(GL_VERTEX_SHADER, 'vs.glsl');
    shaders[1] := TShader.CreateFromFile(GL_FRAGMENT_SHADER, 'ps.glsl');
    fProgram   := TRenderProgram.Create(shaders);
    fVtxBuf:= TGLBuffer.Create(@vertices[0], sizeof(GLfloat) * 9);
    fIdxBuf:= TGLBuffer.Create(@indices[0], sizeof(GLushort) * 3);
    fUniBuf    := TGLBuffer.Create(@transform, SizeOf(transform));
    fProgram.SetUniformBlock('TransformBlock', fUniBuf);
    fVAO := TVertexArray.Create;
    fVAO.EnableAttrib(0);
    fVAO.AttribFormat(0, 3, GL_FLOAT, GL_FALSE);
    fVAO.VertexBuffer(0, fVtxBuf, SizeOf(TGLVector3f));
    fVAO.IndexBuffer(fIdxBuf);
  finally
    for shader in shaders do
      shader.Free;
  end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(fVAO);
  FreeAndNil(fUniBuf);
  FreeAndNil(fVtxBuf);
  FreeAndNil(fIdxBuf);
  FreeAndNil(fProgram);
end;

procedure TForm1.OpenGLControl1Paint(Sender: TObject);
const
  bgColor: TGLVectorf4 = (0.27, 0.53, 0.71, 1.0);
begin
  glClearBufferfv(GL_COLOR, 0, @bgColor);
  fProgram.Use;
  fVAO.Bind;
  glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_SHORT, nil);
  OpenGLControl1.SwapBuffers;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Refresh;
  Update;
end;

end.

