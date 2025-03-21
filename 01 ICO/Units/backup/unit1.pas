unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, RichMemo;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonDeleteNode: TButton;
    ButtonAddNode: TButton;
    Icon1: TImage;
    Icon2: TImage;
    Icon3: TImage;
    Icon4: TImage;
    MenuLineTop: TPanel;
    MenuLineBottom: TPanel;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    RichMemo1: TRichMemo;
    SaveDialog1: TSaveDialog;
    TabSheetTexCode: TTabSheet;
    TabSheetTreeView: TTabSheet;
    VisualTreeView: TTreeView;
    procedure Button1Click(Sender: TObject);
    procedure ButtonAddNodeClick(Sender: TObject);
    procedure ButtonDeleteNodeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Icon1Click(Sender: TObject);
    procedure Icon2Click(Sender: TObject);
    procedure Icon3Click(Sender: TObject);
    procedure Icon4Click(Sender: TObject);
    procedure RichMemo1Change(Sender: TObject);
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

procedure TForm1.ButtonAddNodeClick(Sender: TObject);
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
        NodeText := '[][] New Node';

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

  LaTeXCode := LaTeXCode + '\begin{tikzpicture} [sibling distance=35mm, level distance=20mm, grow = right]' + #13#10;



  //LaTeXCode := LaTeXCode + '\node' ;


  // LaTeX-Code aus dem TreeView generieren
  GenerateLaTeXCodeFromTreeView(VisualTreeView.Items.GetFirstNode, LaTeXCode,0);

  // LaTeX Footer
  LaTeXCode := LaTeXCode + '\end{tikzpicture}' + #13#10;
  LaTeXCode := LaTeXCode + '\end{document}' + #13#10;

  // Generierten LaTeX-Code im RichMemo anzeigen
  RichMemo1.Lines.Text := LaTeXCode;
end;

procedure TForm1.GenerateLaTeXCodeFromTreeView(Node: TTreeNode; var LaTeXCode: string; Level: Integer);
var
  ChildNode: TTreeNode;
  Indentation: string;
  NodeText, EdgeTextOben, EdgeTextUnten, NodeName: string;
  Parts: array of string;
begin
  // Überprüfen, ob der Knoten zugewiesen ist
  if Assigned(Node) then
  begin
    // Erzeuge Einrückung basierend auf der Ebene des Knotens
    Indentation := StringOfChar(' ', Level * 4);  // Vier Leerzeichen pro Ebene

    // Knoten-Text aufteilen: [edgeTextoben][edgeTextunten]Name
    NodeText := Node.Text;

    // Teile den Text basierend auf den eckigen Klammern
    Parts := NodeText.Split(['[', ']']);

    // Überprüfen, ob mindestens 3 Teile vorhanden sind (oben, unten und Name)
    if Length(Parts) >= 3 then
    begin
      EdgeTextOben := Parts[1];  // Der Text für die obere Kante
      EdgeTextUnten := Parts[3]; // Der Text für die untere Kante
      NodeName := Parts[4];      // Der eigentliche Name des Knotens
    end
    else
    begin
      // Falls kein Text in den Klammern ist, verwende den gesamten Text als Name
      EdgeTextOben := '';
      EdgeTextUnten := '';
      NodeName := NodeText;
    end;

    // Den aktuellen Knoten als LaTeX-Knoten hinzufügen
    if Level = 0 then
    begin
      LaTeXCode := LaTeXCode + '\node {' + NodeName + '}' + #13#10;
    end
    else
    begin
      // Beginne das Child und füge die Kanten-Beschreibungen hinzu
      LaTeXCode := LaTeXCode + Indentation + 'child { node {' + NodeName + '}';

      // Wenn der obere Kanten-Text vorhanden ist, füge die obere Kante hinzu
      if EdgeTextOben <> '' then
        LaTeXCode := LaTeXCode + ' edge from parent node[above] {' + EdgeTextOben + '}';

      // Wenn der untere Kanten-Text vorhanden ist, füge die untere Kante hinzu
      if EdgeTextUnten <> '' then
        LaTeXCode := LaTeXCode + ' edge from parent node[below] {' + EdgeTextUnten + '}';

      // Schließe das child-Kommando ab
     // LaTeXCode := LaTeXCode + '}' + #13#10;
    end;

    // Alle Kindknoten rekursiv durchgehen und LaTeX-Code für sie erstellen
    ChildNode := Node.GetFirstChild;
    if Assigned(ChildNode) then
    begin
      // Beginne die Kinderliste für den aktuellen Knoten
      while Assigned(ChildNode) do
      begin
        // Rekursiver Aufruf für das Kind
        GenerateLaTeXCodeFromTreeView(ChildNode, LaTeXCode, Level + 1);
        ChildNode := ChildNode.GetNextSibling;
      end;
    end;

    // Schließe den aktuellen Knoten (wichtig: bei rekursiven Aufrufen)
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

    // Setze den Baum auf den letzten Zustand zurück (hier musst du den Baum erneut aufbauen)
    // Hier könntest du eine Methode einbauen, die den Baum aus dem gespeicherten Zustand wiederherstellt
    // Zum Beispiel:
    // VisualTreeView.Items.Clear;
    // RebuildTreeFromState(LastState);
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

