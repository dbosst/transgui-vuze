{*************************************************************************************
  This file is part of Transmission Remote GUI.
  Copyright (c) 2008-2014 by Yury Sidorov.

  Transmission Remote GUI is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Transmission Remote GUI is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Transmission Remote GUI; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*************************************************************************************}

unit BaseForm;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics;

type

  { TBaseForm }

  TBaseForm = class(TForm)
  private
    FNeedAutoSize: boolean;
    procedure DoScale(C: TControl);
    procedure InitScale;
  protected
    procedure DoCreate; override;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

procedure AutoSizeForm(Form: TCustomForm);
function ScaleInt(i: integer): integer;

var
  IntfScale: integer = 100;

implementation

uses LCLType, ButtonPanel, VarGrid, ComCtrls, StdCtrls, ExtCtrls, lclversion;

var
  ScaleM, ScaleD: integer;

function ScaleInt(i: integer): integer;
begin
  Result:=i*ScaleM div ScaleD;
end;

type THackControl = class(TWinControl) end;

procedure AutoSizeForm(Form: TCustomForm);
var
  i, ht, w, h: integer;
  C: TControl;
begin
  ht:=0;
  for i:=0 to Form.ControlCount - 1 do begin
    C:=Form.Controls[i];
    if not C.Visible then
      continue;
    with C do begin
      if C is TButtonPanel then begin
        TButtonPanel(C).HandleNeeded;
        w:=0;
        h:=0;
        THackControl(C).CalculatePreferredSize(w, h, True);
      end
      else
        h:=Height;
{$ifdef LCLcarbon}
      if C is TPageControl then
        Inc(h, ScaleInt(10));
{$endif LCLcarbon}
      Inc(ht, h + BorderSpacing.Top + BorderSpacing.Bottom + BorderSpacing.Around*2);
    end;
  end;
  ht:=ht + 2*Form.BorderWidth;

  Form.ClientHeight:=ht;
  if Form.ClientHeight <> ht then begin
    Form.Constraints.MinHeight:=0;
    Form.ClientHeight:=ht;
    Form.Constraints.MinHeight:=Form.Height;
  end;
  if Form.BorderStyle = bsDialog then begin
    Form.Constraints.MinHeight:=Form.Height;
    Form.Constraints.MinWidth:=Form.Width;
  end;
end;

{ TBaseForm }

procedure TBaseForm.DoScale(C: TControl);
var
  i: integer;
  R: TRect;
  w, h: integer;
begin
  with C do begin
{$ifdef darwin}
    if C is TButtonPanel then
      exit;
{$endif darwin}
    if C is TWinControl then
      TWinControl(C).DisableAlign;
    try
      if ScaleM <> ScaleD then begin
        ScaleConstraints(ScaleM, ScaleD);
        R := BaseBounds;
        R.Left := ScaleInt(R.Left);
        R.Top := ScaleInt(R.Top);
        R.Right := ScaleInt(R.Right);
        R.Bottom := ScaleInt(R.Bottom);
        if (Parent <> nil) and (Align = alNone) then begin
          if akRight in Anchors then
            Inc(R.Right, C.Parent.ClientWidth - ScaleInt(C.BaseParentClientSize.cx));
          if akBottom in Anchors then
            Inc(R.Bottom, C.Parent.ClientHeight - ScaleInt(C.BaseParentClientSize.cy));
        end;
        BoundsRect := R;
        with BorderSpacing do begin
          Top:=ScaleInt(Top);
          Left:=ScaleInt(Left);
          Bottom:=ScaleInt(Bottom);
          Right:=ScaleInt(Right);
          Around:=ScaleInt(Around);
          InnerBorder:=ScaleInt(InnerBorder);
        end;

        if C is TWinControl then
          with TWinControl(C).ChildSizing do begin
            HorizontalSpacing:=ScaleInt(HorizontalSpacing);
            VerticalSpacing:=ScaleInt(VerticalSpacing);
            LeftRightSpacing:=ScaleInt(LeftRightSpacing);
            TopBottomSpacing:=ScaleInt(TopBottomSpacing);
          end;

        if C is TButtonPanel then
          TButtonPanel(C).Spacing:=ScaleInt(TButtonPanel(C).Spacing);

        if C is TVarGrid then
          with TVarGrid(C).Columns do
            for i:=0 to Count - 1 do
               Items[i].Width:=ScaleInt(Items[i].Width);
        if C is TStatusBar then
          with TStatusBar(C) do
            for i:=0 to Panels.Count - 1 do
               Panels[i].Width:=ScaleInt(Panels[i].Width);
      end;

      // Runtime fixes

      // Fix right aligned label autosize
      if C.Visible and (C is TCustomLabel) and C.AutoSize and (TLabel(C).Alignment = taLeftJustify) and (C.Anchors*[akLeft, akRight] = [akRight]) then begin
        w:=0;
        h:=0;
        THackControl(C).CalculatePreferredSize(w, h, True);
        C.Width:=w;
      end;
{$ifdef darwin}
      // Always use standard button height on OS X for proper theming
      if C.Visible and (C is TCustomButton) then begin
        w:=0;
        h:=0;
        THackControl(C).CalculatePreferredSize(w, h, True);
        C.Height:=h;
      end;
      // Add extra top spacing for group box
      i:=ScaleInt(6);
      if C.Parent is TCustomGroupBox then
        Top:=Top + i;
      if C is TCustomGroupBox then
        with TCustomGroupBox(C).ChildSizing do
          TopBottomSpacing:=TopBottomSpacing + i;
{$endif darwin}
{$ifdef LCLgtk2}
      // Fix panel color bug on GTK2
      if (C is TCustomPanel) and ParentColor and (Color = clDefault) then
        Color:=clForm;
{$endif LCLgtk2}

      if C is TWinControl then
        with TWinControl(C) do
          for i:=0 to ControlCount - 1 do
            DoScale(Controls[i]);
    finally
      if C is TWinControl then
        TWinControl(C).EnableAlign;
    end;
  end;
end;

constructor TBaseForm.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FNeedAutoSize:=AutoSize;
  AutoSize:=False;
end;

procedure TBaseForm.DoCreate;
{$ifdef LCLcarbon}
var
  i: integer;
  {$endif LCLcarbon}
begin
  InitScale;
  HandleNeeded;
  Font.Height:=ScaleInt(-11);
  DoScale(Self);
  if FNeedAutoSize then
    AutoSizeForm(Self);
{$ifdef LCLcarbon}
  // Destroy handles of child controls to fix the LCL Carbon bug.
  // Without this hack, it will not be possible to hide form's controls.
  for i:=0 to ControlCount - 1 do
    if Controls[i] is TWinControl then
      THackControl(Controls[i]).DestroyHandle;
{$endif LCLcarbon}
  inherited DoCreate;
end;

procedure TBaseForm.InitScale;
var
  i: integer;
  tm: TLCLTextMetric;
begin
  if ScaleD <> 0 then exit;
  ScaleD:=11;
  i:=Screen.SystemFont.Height;
  if i = 0 then begin
    if Canvas.GetTextMetrics(tm) then begin
      ScaleM:=tm.Ascender;
      if ScaleM < 11 then
        ScaleM:=11;
    end
    else begin
      ScaleM:=Canvas.TextHeight('Wy');
      ScaleD:=13;
    end;
    if ScaleM = 0 then
      ScaleM:=ScaleD;
  end
  else
    ScaleM:=Abs(i);
  ScaleM:=ScaleM*IntfScale;
  ScaleD:=ScaleD*100;
end;

initialization
  {$I baseform.lrs}

end.

