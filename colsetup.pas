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

unit ColSetup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls, CheckLst, StdCtrls, ButtonPanel, ExtCtrls, VarGrid, BaseForm;

type

  { TColSetupForm }

  TColSetupForm = class(TBaseForm)
    btDown: TButton;
    btUp: TButton;
    Buttons: TButtonPanel;
    lstColumns: TCheckListBox;
    Panel1: TPanel;
    procedure btDownClick(Sender: TObject);
    procedure btOkClick(Sender: TObject);
    procedure btUpClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lstColumnsClick(Sender: TObject);
    procedure lstColumnsClickCheck(Sender: TObject);
  private
    FPersistentColumnId: integer;

    procedure UpdateUI;
    procedure MoveItem(Delta: integer);
  public
    { public declarations }
  end; 

function SetupColumns(LV: TVarGrid; PersistentColumnId: integer; const GridName: string): boolean;

implementation

uses main;

function SetupColumns(LV: TVarGrid; PersistentColumnId: integer; const GridName: string): boolean;
var
  i, j: integer;
begin
  with TColSetupForm.Create(Application) do
  try
    if GridName <> '' then
      Caption:=Caption + ' - ' + GridName;
    FPersistentColumnId:=PersistentColumnId;
    for i:=0 to LV.Columns.Count - 1 do
      with LV.Columns[i] do begin
        j:=lstColumns.Items.Add(Title.Caption);
        lstColumns.Items.Objects[j]:=TObject(ptrint(ID));
        if Width = 0 then
          Visible:=False;
        lstColumns.Checked[j]:=Visible;
        if ID = PersistentColumnId then
          lstColumns.Checked[j]:=True;
      end;
    UpdateUI;
    Result:=ShowModal = mrOk;
    if Result then begin
      LV.BeginUpdate;
      try
        for i:=0 to lstColumns.Items.Count - 1 do
          for j:=0 to LV.Columns.Count - 1 do
            with LV.Columns[j] do
              if ID = ptrint(lstColumns.Items.Objects[i]) then begin
                Index:=i;
                if ID - 1 = PersistentColumnId then
                  lstColumns.Checked[i]:=True;
                if not Visible and (Visible <> lstColumns.Checked[i]) then begin
                  Visible:=True;
                  if Width < 32 then
                    Width:=70;
                end
                else
                  Visible:=lstColumns.Checked[i];
                if not Visible and (LV.SortColumn = ID - 1) and (PersistentColumnId >= 0) then
                  LV.SortColumn:=PersistentColumnId;
                break;
              end;
      finally
        LV.EndUpdate;
      end;
    end;
  finally
    Free;
  end;
  Application.ProcessMessages;
end;

{ TColSetupForm }

procedure TColSetupForm.btOkClick(Sender: TObject);
var
  i: integer;
begin
  for i:=0 to lstColumns.Items.Count - 1 do
    if lstColumns.Checked[i] then begin
      ModalResult:=mrOk;
      exit;
    end;
  MessageDlg('At least single column must be visible.', mtError, [mbOK], 0);
end;

procedure TColSetupForm.btDownClick(Sender: TObject);
begin
  MoveItem(1);
end;

procedure TColSetupForm.btUpClick(Sender: TObject);
begin
  MoveItem(-1);
end;

procedure TColSetupForm.FormCreate(Sender: TObject);
begin
  Buttons.OKButton.ModalResult:=mrNone;
  Buttons.OKButton.OnClick:=@btOKClick;
end;

procedure TColSetupForm.lstColumnsClick(Sender: TObject);
begin
  UpdateUI;
end;

procedure TColSetupForm.lstColumnsClickCheck(Sender: TObject);
var
  i: integer;
begin
  if FPersistentColumnId >= 0 then
    for i:=0 to lstColumns.Items.Count - 1 do
      if ptrint(lstColumns.Items.Objects[i]) = FPersistentColumnId then begin
        lstColumns.Checked[i]:=True;
        break;
      end;
end;

procedure TColSetupForm.UpdateUI;
begin
  btUp.Enabled:=lstColumns.ItemIndex > 0;
  btDown.Enabled:=(lstColumns.ItemIndex >= 0) and (lstColumns.ItemIndex < lstColumns.Items.Count - 1);
end;

procedure TColSetupForm.MoveItem(Delta: integer);
var
  c: boolean;
  OldIdx: integer;
begin
  OldIdx:=lstColumns.ItemIndex;
  c:=lstColumns.Checked[OldIdx];
  lstColumns.Items.Move(OldIdx, OldIdx+Delta);
  lstColumns.Checked[OldIdx+Delta]:=c;
  lstColumns.ItemIndex:=OldIdx+Delta;
  UpdateUI;
end;

initialization
  {$I colsetup.lrs}

end.

