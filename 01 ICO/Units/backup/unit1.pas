unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, RichMemo, ClipBrd,LCLType,LCLIntf, DOM, XMLRead;

type

  { TForm1 }

  TForm1 = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    NodeEditButton: TButton;
    ButtonDeleteNode: TButton;
    ButtonAddNode: TButton;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    NodeEdit1: TLabeledEdit;
    MenuLineNode: TPanel;
    NodeEdit2: TLabeledEdit;
    NodeEdit3: TLabeledEdit;
    Panel2: TPanel;
    PanelMenu1ComboBox: TComboBox;
    Icon1: TImage;
    Icon4: TImage;
    MenuLineTop: TPanel;
    MenuLineBottom: TPanel;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    CostumButton1: TPanel;
    CostumButton2: TPanel;
    Panel1: TPanel;
    PanelMenu1: TPanel;
    PanelMenu2: TPanel;
    RichMemo1: TRichMemo;
    SaveDialog1: TSaveDialog;
    StatusBar1: TStatusBar;
    TabSheetTexCode: TTabSheet;
    TabSheetTreeView: TTabSheet;
    Timer1: TTimer;
    VisualTreeView: TTreeView;
    procedure Button1Click(Sender: TObject);
    procedure ButtonAddNodeClick(Sender: TObject);
    procedure ButtonDeleteNodeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Icon1Click(Sender: TObject);
    procedure Icon2Click(Sender: TObject);
    procedure Icon3Click(Sender: TObject);
    procedure Icon4Click(Sender: TObject);
    procedure NodeEditButtonClick(Sender: TObject);
    procedure RichMemo1Change(Sender: TObject);
    procedure ButtonEnterGrau(Sender: TObject);
    procedure ButtonLeaveGrau(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure AddNode();
    function GetNodeLevelOptionsFromXML(Level: Integer): string;
    function GetGeneralLoadingOptionFromXML: string;
    procedure VisualTreeViewChange(Sender: TObject; Node: TTreeNode);
  private
    FChangeStack: TStringList;
    procedure SaveTreeState;
    procedure UndoLastChange;
    procedure GenerateLaTeXCodeFromTreeView(Node: TTreeNode; var LaTeXCode: string; Level: Integer);
    procedure SaveTreeToFile;
    procedure ImportTreeFromFile;
    procedure GenerateTex;


  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin

end;

procedure TForm1.ButtonEnterGrau(Sender: TObject);
  begin
    if Sender is tpanel then ((sender as TPanel).parent as tpanel).color:=$00E2E2E2;
    if Sender is tlabel then ((sender as tlabel).parent as tpanel).color:=$00E2E2E2;
    if Sender is timage then ((sender as timage).parent as tpanel).color:=$00E2E2E2;
  end;
procedure TForm1.ButtonLeaveGrau(Sender: TObject);
begin
    if Sender is tpanel then ((sender as TPanel).parent as tpanel).color:=cldefault;
    if Sender is tlabel then ((sender as tlabel).parent as tpanel).color:=cldefault;
    if Sender is timage then ((sender as timage).parent as tpanel).color:=cldefault;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  StatusBar1.SimpleText:='';
  Timer1.Enabled:=false;
end;

procedure TForm1.ButtonAddNodeClick(Sender: TObject);
begin
  AddNode();
end;

procedure TForm1.AddNode();
var
  NewNode: TTreeNode;
  NodeText: string;
begin

  if VisualTreeView.Selected <> nil then
  begin
    // show dialog field to get name
    if InputQuery('New Node', 'Text:', NodeText) then
    begin
      // if text empty set default name'
      if NodeText = '' then
      begin
        NodeText := '[][] New Node';
      end
      else
      begin
        NodeText := '[][]'+ NodeText;
        end;


      // Add new node under current node
      NewNode := VisualTreeView.Items.AddChild(VisualTreeView.Selected, NodeText);

      VisualTreeView.Selected.Expanded := True;
    end
  end
  else
  begin
    ShowMessage('Please Select Node');
  end;
  SaveTreeState;
end;

procedure TForm1.ButtonDeleteNodeClick(Sender: TObject);
begin
  // Überprüfen, ob ein Knoten ausgewählt wurde
  if VisualTreeView.Selected <> nil then
  begin
    // Überprüfen, ob der Knoten keine Kinder hat
    if VisualTreeView.Selected.HasChildren then
    begin
      // Falls der Knoten Kinder hat, eine Nachricht anzeigen
      ShowMessage('Der Knoten hat noch Kinder und kann nicht gelöscht werden.');
    end
    else
    begin
      // Den ausgewählten Knoten löschen, wenn er keine Kinder hat
      VisualTreeView.Items.Delete(VisualTreeView.Selected);
    end;
  end
  else
  begin
    // Wenn kein Knoten ausgewählt ist, eine Nachricht anzeigen
    ShowMessage('Bitte wähle einen Knoten zum Löschen aus!');
  end;
  SaveTreeState;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FChangeStack := TStringList.Create;  // Initialisiere den Stack
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FChangeStack.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
   if ((Key = VK_N) and (ssCTRL in Shift)) then
  begin
       AddNode();
       Key := 0;
  end;
end;



procedure TForm1.Icon1Click(Sender: TObject);
begin
  SaveTreeToFile;
end;

procedure TForm1.Icon2Click(Sender: TObject);
begin
     UndoLastChange;
end;

procedure TForm1.Icon3Click(Sender: TObject);
begin
  ImportTreeFromFile;
end;

procedure TForm1.Icon4Click(Sender: TObject);
begin
  GenerateTex;
  PageControl1.ActivePage:= TabSheetTexCode;
  Clipboard.AsText:=RichMemo1.Lines.Text;
  StatusBar1.SimpleText:='Copied to clipboard.';
  Timer1.Enabled:=true;
end;

procedure TForm1.NodeEditButtonClick(Sender: TObject);
  var
    CombinedName: string;
    SelectedNode: TTreeNode;
  begin
    // Hole den aktuell ausgewählten Knoten im TreeView
    SelectedNode := VisualTreeView.Selected;

    // Stelle sicher, dass ein Knoten ausgewählt wurde
    if Assigned(SelectedNode) then
    begin
      // Kombiniere die Teile aus den Edit-Feldern
      CombinedName := '[' + NodeEdit2.Text + ']' + '[' + NodeEdit3.Text + ']' + NodeEdit1.Text;

      // Setze den neuen Namen des Knotens im TreeView
      SelectedNode.Text := CombinedName;
    end
    else
    begin
      ShowMessage('Bitte einen Knoten auswählen!');
    end;
  end;







procedure TForm1.RichMemo1Change(Sender: TObject);
begin

end;

procedure TForm1.GenerateTex;
var
  LaTeXCode: string;
begin
  // LaTeX Header
  LaTeXCode := '\documentclass{article}' + #13#10;
  LaTeXCode := LaTeXCode + '\usepackage{tikz}' + #13#10;
  LaTeXCode := LaTeXCode + '\usetikzlibrary{trees}' + #13#10;
  LaTeXCode := LaTeXCode + '\begin{document}' + #13#10;

  LaTeXCode := LaTeXCode + '\tikzset{   ' + #13#10;
  LaTeXCode := LaTeXCode + 'level 1/.style={sibling distance=4cm, level distance=2cm},  ' + #13#10;
  LaTeXCode := LaTeXCode + 'level 2/.style={sibling distance=3cm, level distance=2cm},  ' + #13#10;
  LaTeXCode := LaTeXCode + 'level 3/.style={sibling distance=2cm, level distance=1.5cm}  ' + #13#10;
  LaTeXCode := LaTeXCode + '}  ' + #13#10;

  LaTeXCode := LaTeXCode + '\begin{tikzpicture} [sibling distance='+LabeledEdit1.Text +'mm,'+ #13#10;
  LaTeXCode := LaTeXCode + ' level distance='+LabeledEdit2.Text+'mm,'+ #13#10;
  LaTeXCode := LaTeXCode + ' grow = '+PanelMenu1ComboBox.Text ;

  if (GetGeneralLoadingOptionFromXML() <> '') then
  begin
    LaTeXCode := LaTeXCode +','+ #13#10 +GetGeneralLoadingOptionFromXML();
  end;



  LaTeXCode := LaTeXCode + #13#10+ ']'+ #13#10  ;



  //LaTeXCode := LaTeXCode + '\node' ;


  // LaTeX-Code aus dem TreeView generieren
  GenerateLaTeXCodeFromTreeView(VisualTreeView.Items.GetFirstNode, LaTeXCode,0);

  // LaTeX Footer
  LaTeXCode := LaTeXCode + '\end{tikzpicture}' + #13#10;
  LaTeXCode := LaTeXCode + '\end{document}' + #13#10;

  // Generierten LaTeX-Code im RichMemo anzeigen
  RichMemo1.Lines.Text := LaTeXCode;
end;

function TForm1.GetGeneralLoadingOptionFromXML: string;
var
  Doc: TXMLDocument;
  GeneralOptionNode: TDOMNode;
begin
  Result := ''; // Standardwert

  if not FileExists('options.xml') then Exit;

  // Lade die XML-Datei
  ReadXMLFile(Doc, 'options.xml');

  GeneralOptionNode := Doc.DocumentElement.FindNode('GeneralLoadingOption');

  if Assigned(GeneralOptionNode) then
  begin
    Result := GeneralOptionNode.TextContent;
  end;

  Doc.Free;
end;

procedure TForm1.VisualTreeViewChange(Sender: TObject; Node: TTreeNode);
var
  NodeText, CaptionTop, CaptionBottom, NamePart: string;
begin
  if Assigned(Node) then
  begin
    NodeText := Node.Text;

    // Initialisiere die Variablen für die Teile
    CaptionTop := '';
    CaptionBottom := '';
    NamePart := '';

    // Extrahiere "Caption Top"
    if (Pos('[', NodeText) > 0) and (Pos(']', NodeText) > 0) then
    begin
      CaptionTop := Copy(NodeText, Pos('[', NodeText) + 1, Pos(']', NodeText) - Pos('[', NodeText) - 1);
      NodeText := Copy(NodeText, Pos(']', NodeText) + 1, Length(NodeText));  // Entferne das gefundene "[Caption Top]"
    end;

    // Extrahiere "Caption Bottom"
    if (Pos('[', NodeText) > 0) and (Pos(']', NodeText) > 0) then
    begin
      CaptionBottom := Copy(NodeText, Pos('[', NodeText) + 1, Pos(']', NodeText) - Pos('[', NodeText) - 1);
      NodeText := Copy(NodeText, Pos(']', NodeText) + 1, Length(NodeText));  // Entferne das gefundene "[Caption Bottom]"
    end;

    // Der restliche Text ist der Name
    NamePart := NodeText;


    NodeEdit1.Text :=  NamePart;
    NodeEdit2.Text:= CaptionTop;
    NodeEdit3.Text:= CaptionBottom;

  end;
end;



function TForm1.GetNodeLevelOptionsFromXML(Level: Integer): string;
var
  Doc: TXMLDocument;
  RootNode, LevelNode: TDOMNode;
  i: Integer;
begin
  Result := ''; // Standardwert

  if not FileExists('options.xml') then Exit;

  ReadXMLFile(Doc, 'options.xml');
  RootNode := Doc.DocumentElement;


  for i := 0 to RootNode.ChildNodes.Count - 1 do
  begin
    LevelNode := RootNode.ChildNodes[i];
    if Assigned(LevelNode) and (LevelNode.NodeName = 'Level') then
    begin
      if StrToIntDef(LevelNode.Attributes.GetNamedItem('index').NodeValue, -1) = Level then
      begin
        Result := LevelNode.TextContent;
        Break;
      end;
    end;
  end;

  Doc.Free;
end;

procedure TForm1.GenerateLaTeXCodeFromTreeView(Node: TTreeNode; var LaTeXCode: string; Level: Integer);
var
  ChildNode: TTreeNode;
  Indentation, NodeText, EdgeTextOben, EdgeTextUnten, NodeName, NodeOptions: string;
  Parts: array of string;
begin
  if Assigned(Node) then
  begin
    Indentation := StringOfChar(' ', Level * 4);
    NodeText := Node.Text;
    Parts := NodeText.Split(['[', ']']);

    if Length(Parts) >= 5 then
    begin
      EdgeTextOben := Parts[1];
      EdgeTextUnten := Parts[3];
      NodeName := Parts[4];
    end
    else if Length(Parts) = 3 then
    begin
      EdgeTextOben := Parts[1];
      EdgeTextUnten := '';
      NodeName := Parts[2];
    end
    else
    begin
      EdgeTextOben := '';
      EdgeTextUnten := '';
      NodeName := NodeText;
    end;

    // Lade die Optionen basierend auf der Tiefe (Level) des Knotens
    NodeOptions := GetNodeLevelOptionsFromXML(Level);

    if Level = 0 then
    begin
      LaTeXCode := LaTeXCode + '\node' + '[' + NodeOptions + '] {' + NodeName + '}' + #13#10;
    end
    else
    begin
      LaTeXCode := LaTeXCode + Indentation + 'child { node' + '[' + NodeOptions + '] {' + NodeName + '}';
    end;

    ChildNode := Node.GetFirstChild;
    while Assigned(ChildNode) do
    begin
      GenerateLaTeXCodeFromTreeView(ChildNode, LaTeXCode, Level + 1);
      ChildNode := ChildNode.GetNextSibling;
    end;

    if EdgeTextOben <> '' then
      LaTeXCode := LaTeXCode + ' edge from parent node[above] {' + EdgeTextOben + '}';
    if EdgeTextUnten <> '' then
      LaTeXCode := LaTeXCode + ' edge from parent node[below] {' + EdgeTextUnten + '}';

    if Level > 0 then
      LaTeXCode := LaTeXCode + Indentation + '}' + #13#10;
  end;
end;











procedure TForm1.SaveTreeState;
var
  Node: TTreeNode;
  NodeState: string;
begin
  // Überprüfen, ob FChangeStack korrekt initialisiert wurde
  if not Assigned(FChangeStack) then
  begin
    ShowMessage('FChangeStack wurde nicht initialisiert!');
    Exit;
  end;

  // Gehe durch alle Knoten und speichere ihren Zustand in einer Zeichenkette
  NodeState := '';
  Node := VisualTreeView.Items.GetFirstNode;
  while Assigned(Node) do
  begin
    NodeState := NodeState + Node.Text + ' ';
    Node := Node.GetNextSibling;
  end;

  // Speichern des Zustands im Stack
  FChangeStack.Add(NodeState);
end;




procedure TForm1.UndoLastChange;
var
  LastState: string;
begin
  if FChangeStack.Count > 0 then
  begin
    // Hole den letzten Zustand
    LastState := FChangeStack[FChangeStack.Count - 1];

    // Den Stack nach der Rückgängigmachung um einen Schritt verringern
    FChangeStack.Delete(FChangeStack.Count - 1);


  end
  else
  begin
    ShowMessage('Keine Änderungen zum Zurücksetzen.');
  end;
end;








procedure TForm1.SaveTreeToFile;
var
  FileName: string;
  Node: TTreeNode;
  TreeList: TStringList;

  // Rekursive Methode, um den Baum als Text zu speichern
  procedure SaveNode(Node: TTreeNode; Level: Integer);
  var
    Indentation: string;
  begin
    // Erzeuge die Einrückung basierend auf der Baum-Ebene
    Indentation := StringOfChar(' ', Level * 4);  // 4 Leerzeichen pro Ebene

    // Füge den Knoten-Text zur Liste hinzu
    TreeList.Add(Indentation + Node.Text);

    // Gehe rekursiv durch die Kindknoten
    Node := Node.GetFirstChild;
    while Assigned(Node) do
    begin
      SaveNode(Node, Level + 1);
      Node := Node.GetNextSibling;
    end;
  end;

begin
  // Zeige den Speichern-Dialog an
  if SaveDialog1.Execute then
  begin
    FileName := SaveDialog1.FileName;  // Hole den ausgewählten Dateipfad

    // Erstelle eine neue TStringList zum Speichern der Textdaten
    TreeList := TStringList.Create;
    try
      // Speichere alle Knoten des Baumes
      Node := VisualTreeView.Items.GetFirstNode;
      while Assigned(Node) do
      begin
        SaveNode(Node, 0); // 0 ist das Root-Level
        Node := Node.GetNextSibling;
      end;

      // Speichere die gesamte Baumstruktur in eine Datei
      TreeList.SaveToFile(FileName);
    finally
      TreeList.Free;
    end;
  end;
end;


procedure TForm1.ImportTreeFromFile;
var
  FileName: string;
  TreeList: TStringList;
  Line: string;
  NodeStack: array of TTreeNode;  // Stack für Knoten
  CurrentLevel: Integer;
  NodeText: string;
  NewNode: TTreeNode;
  i: Integer;
begin
  // Zeige den Öffnen-Dialog an
  if OpenDialog1.Execute then
  begin
    FileName := OpenDialog1.FileName;  // Hole den ausgewählten Dateipfad

    // Lade die Textdatei in eine TStringList
    TreeList := TStringList.Create;
    try
      TreeList.LoadFromFile(FileName);  // Datei einlesen

      // Leere das TreeView
      VisualTreeView.Items.Clear;

      // Initialisiere den Stack
      SetLength(NodeStack, 0);  // Sicherstellen, dass der Stack leer ist
      CurrentLevel := 0;

      // Gehe jede Zeile der Datei durch
      for i := 0 to TreeList.Count - 1 do
      begin
        Line := TreeList[i];

        // Berechne das Level basierend auf der Anzahl der führenden Leerzeichen
        CurrentLevel := 0;
        while (Length(Line) > 0) and (Line[1] = ' ') do
        begin
          Delete(Line, 1, 1);  // Entferne führende Leerzeichen
          Inc(CurrentLevel);  // Erhöhe das Level
        end;

        // Der Text des Knotens ist der verbleibende Text in der Zeile
        NodeText := Line;

        // Füge den Knoten zum Baum hinzu, abhängig von der Ebene
        if CurrentLevel = 0 then
        begin
          // Erstelle einen neuen Root-Knoten
          NewNode := VisualTreeView.Items.Add(nil, NodeText);
          SetLength(NodeStack, 1);  // Stelle sicher, dass der Stack nur ein Element enthält
          NodeStack[0] := NewNode;  // Setze den Root-Knoten im Stack
        end
        else
        begin
          // Wenn das Level höher ist, füge einen Knoten auf der entsprechenden Ebene hinzu
          if CurrentLevel > Length(NodeStack) - 1 then
          begin
            // Erstelle einen neuen Knoten und füge ihn zum Stack hinzu
            NewNode := VisualTreeView.Items.AddChild(NodeStack[CurrentLevel - 1], NodeText);
            SetLength(NodeStack, CurrentLevel + 1);  // Erweitere den Stack
            NodeStack[CurrentLevel] := NewNode;  // Setze den aktuellen Knoten im Stack
          end
          else
          begin
            // Der Knoten gehört zu einer tieferen Ebene, setze den Knoten im Stack
            NodeStack[CurrentLevel] := VisualTreeView.Items.AddChild(NodeStack[CurrentLevel - 1], NodeText);
          end;
        end;

        // Optional: Du kannst den Knoten auch ausklappen, wenn nötig
        // NewNode.Expanded := True;  // Bei Bedarf ausklappen
      end;

    finally
      TreeList.Free;
    end;
  end;
end;









end.

