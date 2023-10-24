open Raylib

let () = print_endline ""
let () = print_endline "*************************************"
let () = print_endline "********** Starting MTD! ************"
let () = print_endline "*************************************"
let () = print_endline ""

(*Constants********************************************************************)
module Constants = struct
  (*Custom Types*)
  type gamestate = Home | Active

  (*Screen Constants*)
  let screen_width = 1100
  let screen_height = 720

  (*Current Gamestate*)
  let state = ref Home

  (*Art. These have to be options because they are not initially set when main
     runs*)
  let title_font = ref None
  let background = ref None
  let red_bal_texture = ref None
end

(*Utility Functions*)
let round_float x = int_of_float (Float.round x)

(*Home screen balloons**********************************************************)
module Balloon = struct
  let balloon_h_radius = 20.
  let balloon_v_radius = 25.

  type balloon = {
    x : float;
    y : float;
    speed : float;
    bal_texture : Texture2D.t;
  }

  let gen_balloon x y speed bal_texture = { x; y; speed; bal_texture }

  let rec generate_all_balloons x_pos_start count : balloon list =
    if x_pos_start < Constants.screen_width - 100 then
      let rand_x = Random.float 300. in
      let rand_y = Random.int 200 in
      let rand_speed = Random.float 1. in
      gen_balloon
        (float_of_int x_pos_start +. rand_x)
        (float_of_int (Constants.screen_height + rand_y))
        (rand_speed +. 1.)
        (Option.get !Constants.red_bal_texture)
      :: generate_all_balloons (x_pos_start + int_of_float rand_x) (count - 1)
    else []

  let update_balloon_position balloon =
    let new_y =
      if balloon.y < -70. then 650. +. 70. else balloon.y -. balloon.speed
    in
    { balloon with y = new_y }

  let rec update_balloon_positions (balloons : balloon list) =
    match balloons with
    | [] -> []
    | h :: t -> update_balloon_position h :: update_balloon_positions t

  let draw_balloon balloon =
    draw_texture_ex balloon.bal_texture
      (Vector2.create balloon.x balloon.y)
      0.0 0.15 Color.white

  let rec draw_balloons (balloons : balloon list) =
    match balloons with
    | [] -> ()
    | h :: t ->
        draw_balloon h;
        draw_balloons t

  let check_clicked balloon (click_pos : Vector2.t) : bool =
    (*Magic numbers represent the offset from the top left corner of png to
       actual center of balloon ellipse.*)
    let bal_x = balloon.x +. 29.0 in
    let bal_y = balloon.y +. 35.0 in
    if
      Vector2.x click_pos < bal_x +. balloon_h_radius
      && Vector2.x click_pos > bal_x -. balloon_h_radius
      && Vector2.y click_pos < bal_y +. balloon_v_radius
      && Vector2.y click_pos > bal_y -. balloon_v_radius
    then true
    else false

  let rec check_clicked_all_balloons balloons (click_pos : Vector2.t) :
      balloon list =
    print_string "hello";
    match balloons with
    | [] -> []
    | balloon :: rest ->
        if check_clicked balloon click_pos then
          check_clicked_all_balloons rest click_pos
        else balloon :: check_clicked_all_balloons rest click_pos
end

open Constants

(*Loads images and fonts for use on the home screen. This function sets the global
   constants background, red_bal_texture, and title_font.*)
let gui_setup () =
  let title_font = Raylib.load_font_ex "machine-gunk.ttf" 100 None in
  let custom_font = Raylib.load_font_ex "machine-gunk.ttf" 24 None in
  Raygui.set_font custom_font;
  (*Create the intro screen art*)
  let intro_screen_art = Raylib.load_image "MTDCoverArt.png" in
  let background = Raylib.load_texture_from_image intro_screen_art in
  unload_image intro_screen_art;

  let red_balloon = Raylib.load_image "red.png" in
  let red_bal_texture = Raylib.load_texture_from_image red_balloon in
  unload_image red_balloon;

  Constants.background := Some background;
  Constants.red_bal_texture := Some red_bal_texture;
  Constants.title_font := Some title_font

(*Current set of balloons*)
let balloons = ref []

let setup () =
  Raylib.init_window screen_width screen_height "MTD";
  Raylib.set_target_fps 60;

  (*Create the intro screen art*)
  gui_setup ();

  Raygui.(set_style (TextBox `Text_alignment) TextAlignment.(to_int Center));
  (* SETTING STYLE TO RED - USE HEX*)
  Raygui.(set_style (Button `Base_color_normal) 0xFF000010);
  Raygui.(set_style (Button `Text_color_normal) 0xFFFFFF);
  Raygui.set_style (Default `Text_size) 24;

  Raygui.(set_style (Button `Border_width) 0);

  balloons := Balloon.generate_all_balloons 0 12

(*Updates game)*)
let update_home () =
  (if is_mouse_button_pressed Left then
     let click_pos = get_mouse_position () in
     balloons := Balloon.check_clicked_all_balloons !balloons click_pos);
  balloons := Balloon.update_balloon_positions !balloons

(*Draws home screen for MTD.*)
let draw_home () =
  begin_drawing ();
  (***** BACKGROUND *****)
  draw_texture_ex
    (Option.get !Constants.background)
    (Vector2.create 0. 0.0) (* Position *)
    0.0 (* Rotation (in radians) *)
    0.60 (* Scale *)
    Color.white;

  (* create -> x y width height*)
  if Raygui.(button (Rectangle.create 660. 370. 120. 50.) "PLAY") then
    Constants.state := Active;
  (* Raylib.set_texture_filter (Font.texture (Raylib.get_font_default ())) TextureFilter.Point; *)
  draw_text_ex
    (Option.get !Constants.title_font)
    "McGraw Tower" (Vector2.create 430. 140.) 100. 3. (Color.create 255 6 0 255);
  draw_text_ex
    (Option.get !Constants.title_font)
    "Defense" (Vector2.create 570. 250.) 100. 3. (Color.create 255 6 0 255);

  (***** BALLOONS *****)
  Balloon.draw_balloons !balloons;

  end_drawing ()

(*Updates and draws the window based on the current gamestate.*)
let update_and_draw () =
  update_home ();
  if !Constants.state = Active then
    let open MTD in
    Dragdrop.loop ()
  else draw_home ()

(*This is the main game loop. This is the loop that is recursively called every
   tick to generate the next frame. Depending on the gamestate, a different
   function is chosen to update then draw the game.*)
let rec loop () =
  if Raylib.window_should_close () then Raylib.close_window ()
  else update_and_draw ();
  loop ()

let () =
  setup ();
  loop ()
