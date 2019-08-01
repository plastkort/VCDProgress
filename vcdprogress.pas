unit VCDProgress;

interface

uses
  windows, SysUtils, types, graphics, Classes, Controls;

type
  TProgressType = (ptPercent, ptText);
  TOnProgress   = procedure (sender : TObject; Progress : byte; Position : int64; Max : int64) of object;
  TOnComplete   = procedure (sender : TObject; Position : int64; Max : int64) of object;
  TVCDProgress = class(TCustomControl)
  private
    FMax           : int64;
    FBGColor       : TColor;
    FProgressColor : TColor;
    FPosition      : int64;
    ProgresBitmap  : TBitmap;
    FLeftCaption: string;
    FRightCaption: string;
    FFontRight: TFont;
    FFontLeft: TFont;
    FProgressType: TProgressType;
    FOnProgress: TOnProgress;
    FOnComplete: TOnComplete;
    FColorFaded: TColor;
    procedure DrawBorder;
    procedure DrawProgress;
    procedure DrawLeftString;
    procedure DrawRightString;
    function BlendRGB(const Color1, Color2: TColor;      const Blend: Integer): TColor;
    procedure SetBGColor(const Value: TColor);
    procedure SetProgressColor(const Value: TColor);
    procedure SetMax(const Value: int64);
    procedure SetPosition(const Value: int64);
    procedure SetLeftCaption(const Value: string);
    procedure SetRightCaption(const Value: string);
    procedure SetFontLeft(const Value: TFont);
    procedure SetFontRight(const Value: TFont);
    procedure SetProgressType(const Value: TProgressType);
    procedure FontChanged (sender: TObject);
    procedure SetColorEnd(const Value: TColor);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
  published
    property OnProgress       : TOnProgress read FOnProgress  write FOnProgress;
    property OnComplete       : TOnComplete read FOnComplete  write FOnComplete;
    property ProgressType     : TProgressType read FProgressType  write SetProgressType;
    property FontLeft         : TFont  read FFontLeft      write SetFontLeft;
    property FontRight        : TFont  read FFontRight     write SetFontRight;
    property CaptionLeft      : string read FLeftCaption   write SetLeftCaption;
    property CaptionRight     : string read FRightCaption  write SetRightCaption;
    property ProgressMax      : int64  read FMax           write SetMax;
    property ProgressPosition : int64  read FPosition      write SetPosition;
    property ColorBackground  : TColor read FBGColor       write SetBGColor;
    property ColorProgress    : TColor read FProgressColor write SetProgressColor;
    property ColorFaded       : TColor read FColorFaded    write SetColorEnd;
    property Align;
    property Anchors;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Visual Card Designer', [TVCDProgress]);
end;

{ TVCDProgress }

constructor TVCDProgress.Create(AOwner: TComponent);
begin
  inherited;
  DoubleBuffered := true;
  if not(csReading in ComponentState) then
  begin
    width  := 200;
    height := 16;
    FMax   := 100;
    FPosition := 50;
    ColorProgress := $004080FF;
    ColorBackground := clGray;
    ColorFaded    := clWhite;
    CaptionLeft := 'Progress Indicator';
  end;
  FFontLeft  := TFont.Create;
  FFontRight := TFont.create;
  FontLeft.OnChange := FontChanged; 
  FontRight.OnChange := FontChanged; 

  ProgresBitmap := TBitmap.create;
  ProgresBitmap.width  := width;
  ProgresBitmap.Height := height;
end;

destructor TVCDProgress.Destroy;
begin
  FreeAndNil(ProgresBitmap);
  FFontLeft.Free;
  FFontRight.Free;
  inherited;
end;

procedure TVCDProgress.DrawBorder;
begin
  with ProgresBitmap.Canvas do
  begin
    Pen.Color := ClBlack;
    MoveTo(Width-1, 0);
    LineTo(0, 0);
    LineTo(0, Height);
    Pen.Color := clBlack;
    MoveTo(1, Height-1);
    LineTo(Width-1, Height-1);
    LineTo(Width-1, 0);
  end;
end;

function TVCDProgress.BlendRGB(const Color1, Color2 : TColor; const Blend : Integer): TColor;
type
  TColorBytes = array[0..3] of Byte;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 2 do
  TColorBytes(Result)[I] := Integer(TColorBytes(Color1)[I] +
                                   ((TColorBytes(Color2)[I] - TColorBytes(Color1)[I]) * Blend) div 63);
end;


procedure TVCDProgress.DrawProgress;
var
  CS: TPoint;
  Z: Integer;
  MyColor : TColor;
  Progress : Int64;
begin
  CS := ClientRect.BottomRight;
  with ProgresBitmap.Canvas do
  begin
    Progress := (FPosition * width div FMax);
    for Z := 0 to 63 do
    begin
      { Background }
      MyColor := ColorToRGB(FBGColor);
      Brush.Color := BlendRGB(ColorToRGB(FColorFaded), MyColor, Z) or $02000000;
      FillRect (Rect(0, MulDiv(CS.Y, Z, 63), CS.X, MulDiv(CS.Y, Z+1, 63)));
      { PRogress}
      MyColor := ColorToRGB(FProgressColor);
      Brush.Color := BlendRGB(ColorToRGB(FColorFaded), MyColor, Z) or $02000000;
      FillRect (Rect(0, MulDiv(CS.Y, Z, 63), Progress,height));
    end;
  end;
end;

procedure TVCDProgress.Paint;
begin
  inherited;
  ProgresBitmap.Width := Width;
  ProgresBitmap.Height := Height;

 DrawProgress;
 DrawBorder;

 if trim(FLeftCaption) <> '' then
 DrawLeftString;
 DrawRightString;

 Canvas.Draw(0, 0, ProgresBitmap);
{ self.ShowHint := true;
 self.Hint := FLeftCaption;}

end;

procedure TVCDProgress.SetBGColor(const Value: TColor);
begin
  FBGColor := Value;
  invalidate;
end;

procedure TVCDProgress.SetProgressColor(const Value: TColor);
begin
  FProgressColor := Value;
  invalidate;
end;

procedure TVCDProgress.SetMax(const Value: int64);
begin
  FMax := Value;
  invalidate
end;

procedure TVCDProgress.SetPosition(const Value: int64);
begin
  FPosition := Value;
  invalidate
end;

procedure TVCDProgress.SetLeftCaption(const Value: string);
begin
  FLeftCaption := Value;
  Invalidate;
end;

procedure TVCDProgress.SetRightCaption(const Value: string);
begin
  FRightCaption := Value;
  Invalidate;
end;

procedure TVCDProgress.SetFontLeft(const Value: TFont);
begin
  FFontLeft.assign(Value);
  Invalidate;
end;

procedure TVCDProgress.SetFontRight(const Value: TFont);
begin
  FFontRight.assign(Value);
  Invalidate;
end;

function SS(C: TCanvas; const S: AnsiString; W: Integer): AnsiString;
begin
  Result := S;
  if C.TextWidth(Result) <= W then
    Exit;
  while (C.TextWidth(Result + '...') > W) and (Length(Result) > 1) do
    SetLength(Result, Length(Result) - 1);
  Result := Result + '...';
  while (C.TextWidth(Result) > W) and (Length(Result) > 0) do
    SetLength(Result, Length(Result) - 1);
end;


procedure TVCDProgress.DrawLeftString;
var
MyString : string;
begin
  with ProgresBitmap.Canvas do
  begin
    Brush.Style := bsClear;
    Font.assign(FFontLeft);
    if ProgressType = ptText then
    begin
      MyString := SS(ProgresBitmap.Canvas,FLeftCaption,self.Width - TextWidth(FRightCaption));
    end else
    begin
      MyString := SS(ProgresBitmap.Canvas, FLeftCaption, Self.Width - TextWidth('100%'))
    end;
    TextOut(1, (self.Height div 2) - (TextHeight(MyString) div 2),MyString);
  end;
end;

procedure TVCDProgress.DrawRightString;
var
  OutputText : string;
  Progress   : integer;
begin
  with ProgresBitmap.Canvas do
  begin
    Brush.Style := bsClear;
    Font.assign(FFontRight);

    Progress := trunc(FPosition * 100 / FMax);
    if assigned(FOnProgress) then
      FOnProgress(self, Progress, ProgressPosition, ProgressMax);

    if assigned(FOnComplete) and (FPosition = FMax) then
      FOnComplete(self, ProgressPosition, ProgressMax);

    if FProgressType = ptPercent then
    OutputText :=  format('%d%%',[Progress])
    else Outputtext := FRightCaption;

    TextOut((Self.Width - TextWidth(OutputText)-2),(self.Height div 2) - (TextHeight(OutputText) div 2), OutputText);
  end;
end;

procedure TVCDProgress.SetProgressType(const Value: TProgressType);
begin
  FProgressType := Value;
  Invalidate;
end;

procedure TVCDProgress.FontChanged(sender: TObject);
begin
  Invalidate;
end;

procedure TVCDProgress.SetColorEnd(const Value: TColor);
begin
  FColorFaded := Value;
  invalidate;
end;

end.
