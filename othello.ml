let cell_size = ref 25
let bg_r = ref 199
let bg_g = ref 222
let bg_b = ref 109

type cell = White | Black | Empty
type board = (cell array) array

(* 3.1 *)

let make_reversi_board = 
let size = 10 in
Array.init
size
(fun y ->
  Array.init
  size
  (fun x -> Empty)
)
;;

let make_board = 
let board = make_reversi_board in
board.((Array.length board) / 2 - 1).((Array.length board) / 2 - 1) <- White;
board.((Array.length board) / 2 + 0).((Array.length board) / 2 + 0) <- White;
board.((Array.length board) / 2 + 0).((Array.length board) / 2 - 1) <- Black;
board.((Array.length board) / 2 - 1).((Array.length board) / 2 + 0) <- Black;
board
;;

(* 3.2 *)
let display_cell board x y =
  Graphics.set_color (Graphics.rgb !bg_r !bg_g !bg_b);
  Graphics.fill_rect
  (y * !cell_size + 1)
  (x * !cell_size + 1)
  (!cell_size - 2)
  (!cell_size - 2);
  Graphics.set_color Graphics.black;
  Graphics.draw_rect 
  (y * !cell_size)
  (x * !cell_size) 
  (y + !cell_size - y) 
  (x + !cell_size - x);
  Graphics.set_color 
  (match board.(y).(x) with 
    | Black -> Graphics.black
  | _ -> Graphics.white);
  if (not (board.(y).(x) = Empty)) then
  (
    Graphics.fill_circle
    (y * !cell_size + !cell_size/2) 
    (x * !cell_size + !cell_size/2) 
    (!cell_size / 2 - 2);
    Graphics.set_color Graphics.black;
    Graphics.draw_circle 
    (y * !cell_size + !cell_size/2) 
    (x * !cell_size + !cell_size/2) 
    (!cell_size / 2 - 2);    
  )
;;

let display_board board =
  Graphics.open_graph
  (Printf.sprintf
   " %dx%d"
   (!cell_size * Array.length board.(0)+1)
   (21 + !cell_size * Array.length board.(0)));
  for i=0 to Array.length board-1 do
  for j=0 to Array.length board.(i)-1 do
  display_cell board i j;
done;
done;
;;

let display_message message =
  Graphics.moveto 2 (Graphics.size_y()-18);
  Graphics.set_color Graphics.black;
  Graphics.draw_string message
;;

(* 3.3 *)

let is_finished board = 
  let finished = ref true in
  for i=0 to Array.length board-1 do
  for j=0 to Array.length board.(i)-1 do
  if board.(j).(i) = Empty then
  finished := false;
done;
done;
!finished
;;

let check_pos board x y =
  x >= 0 && 
  y >= 0 && 
  y < Array.length board && 
  x < Array.length board.(0)
;;

let get_opponent c =
  match c with
  | White -> Black
  | _ -> White
;;

(* 5.1 *)
let playable_dir board c (x, y) (dx, dy) =
  let rec playable_dir_rec (x, y) valid = 
  if not (check_pos board x y) then
  false
else(
  match board.(x).(y) with
  | Empty -> false
  | cell ->
  if cell = (get_opponent c) then 
  playable_dir_rec (x + dx, y + dy) true
else 
  valid
)
in playable_dir_rec (x + dx, y + dy) false
;;

let playable_cell board c x y =
  if not (check_pos board x y) then
  false
else(
  let directions = 
  [ (-1, -1); (-1, 0); (-1, 1); (0, -1); (0, 1); (1, -1); (1, 0); (1, 1) ]
in
match board.(x).(y) with
| Empty -> (true && (List.fold_left
  (fun a b -> a || b) 
  false
  (List.map 
    (fun d -> playable_dir board c (x, y) d) 
  directions))) 
| _ -> false
)
;;

let play_cell board c x y =
  let directions = 
  [ (-1, -1); (-1, 0); (-1, 1); (0, -1); (0, 1); (1, -1); (1, 0); (1, 1) ]
  and opponent = (get_opponent c)
in
(List.iter 
  (fun (dx, dy) -> 
    if (playable_dir board c (x, y) (dx, dy)) then
    let rec take (x, y) =
    if (check_pos board x y) then
    if (board.(x).(y) = opponent) then(
      board.(x).(y) <- c; 
      take (x + dx, y + dy)
    )
  in take (x + dx, y + dy)
)
directions);
board.(x).(y) <- c
;;

(* 4.1 *)
let player_turn board =
  let rec player_turn_rec ()=
  let st = Graphics.wait_next_event [Graphics.Button_down] in
  let x = (st.Graphics.mouse_x / !cell_size) and y = (st.Graphics.mouse_y / !cell_size) in
  if (playable_cell board Black x y) then
  play_cell board Black x y
else
  player_turn_rec ()
in player_turn_rec ()
;;


let rec ia_turn board = 
  let x = Random.int (Array.length board) in
  let y = Random.int (Array.length board.(0)) in
  match board.(x).(y) with
  | Empty -> 
  if (playable_cell board White x y) then
  play_cell board White x y
else
  ia_turn board
  | _ -> ia_turn board
;;



(* 4.2 *)

let count_white board = 
  let res = ref 0 in
  for i = 0 to (Array.length board) - 1 do
  for j = 0 to (Array.length board.(0)) - 1 do
  if board.(i).(j)=White then
  res := succ !res;
done;
done;
!res
;;


let end_message board = 
  let whites = (count_white board) 
  and total = ((Array.length board) * (Array.length board.(0))) in
  if (whites > (total / 2)) then
  "White wins by "^string_of_int(whites - total + whites)^" !"
else
  if (whites < (total / 2)) then
  "Black wins by "^string_of_int(total - whites - whites)^" !"
else
  "Draw !"
;;


let continue() =
let st = (Graphics.wait_next_event [Graphics.Button_down]) in 
st.Graphics.button <> true
;;

let game ()=
let board = ref make_board in

display_board !board;

while not (is_finished !board) do
  display_message "Black to play...";
  player_turn !board;  
  display_board !board;
  display_message "White to play...";
  ia_turn !board;
  display_board !board;
done;

display_message (end_message !board);

while continue() do
  ()
done;
Graphics.close_graph
;;


let speclist = [
("-size", Arg.Int (fun s -> cell_size := s), "<int> : set cell size in pixels");
("-background", Arg.Tuple [
  Arg.Int (fun r -> bg_r := r); 
  Arg.Int (fun g -> bg_g := g); 
  Arg.Int (fun b -> bg_b := b)], "<int> <int> <int> : set background (RGB)");
]

let main () =
  (Arg.parse
    speclist
    (fun x -> raise (Arg.Bad ("Bad argument : " ^ x)))
    "othello");
  game()
;;

main();