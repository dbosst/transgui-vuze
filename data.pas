unit data;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, FileUtil, LResources, Controls;

type
  { TDM }

  TDM = class(TDataModule)
    ImageList16: TImageList;
    procedure DataModuleCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  DM: TDM;

implementation

uses
  Graphics, GraphType, ImgList;

procedure ResizeImageList(IL: TImageList; NewWidth, NewHeight: integer);
var
  cil: TImageList;
  I: Integer;
  Image, bmp: TBitmap;
  ARect: TRect;
begin
  cil:=TImageList.Create(nil);
  IL.BeginUpdate;
  try
    cil.Assign(IL);
    IL.Width:=NewWidth;
    IL.Height:=NewHeight;
    IL.Masked:=True;
    with IL do begin
      ARect := Rect(0, 0, Width, Height);
      Image := TBitmap.Create;
      bmp := TBitmap.Create;
      try
        with Image do begin
          PixelFormat:=pf32bit;
          Width := NewWidth;
          Height := NewHeight;
          Canvas.Brush.Color:=clBlue;
        end;
        with bmp do begin
          PixelFormat:=pf32bit;
          Height := cil.Height;
          Width := cil.Width;
          Canvas.Brush.Color:=clBlack;
        end;
        for I := 0 to cil.Count - 1 do begin
          with Image.Canvas do begin
            FillRect(ARect);
            bmp.Canvas.FillRect(0, 0, Width, Height);
            cil.Draw(bmp.Canvas, 0, 0, I, dsNormal, itImage, gdeNormal);
            StretchDraw(ARect, bmp);
          end;
          AddMasked(Image, clNone);
        end;
      finally
        bmp.Free;
        Image.Free;
      end;
    end;
  finally
    IL.EndUpdate;
    cil.Free;
  end;
end;

{ TDM }

procedure TDM.DataModuleCreate(Sender: TObject);
var
  a: single;
begin
  a:=Screen.PixelsPerInch/96;
  if a > 1.5 then begin
    a:=a*0.7;
    ResizeImageList(ImageList16, Round(ImageList16.Width*a), Round(ImageList16.Height*a));
  end;
end;

initialization
  {$I data.lrs}

end.

