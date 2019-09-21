module Dropdown exposing
    ( State, Config, ToggleEvent(..)
    , dropdown, toggle, drawer
    )

{-| Flexible dropdown component which serves as a foundation for custom dropdowns, select–inputs, popovers, and more.


# Example

Basic example of usage:

    init : Model
    init =
        { myDropdown = False }

    type alias Model =
        { myDropdown : Dropdown.State }

    type Msg
        = ToggleDropdown Bool

    update : Msg -> Model -> Model
    update msg model =
        case msg of
            ToggleDropdown newState ->
                { model | myDropdown = newState }

    view : Model -> Html Msg
    view model =
        div []
            [ dropdown
                myDropdownConfig
                model.myDropdown
                div
                []
                [ \config state ->
                    toggle config state button [] [ text "Toggle" ]
                , \config state ->
                    drawer config
                        state
                        div
                        []
                        [ button [] [ text "Option 1" ]
                        , button [] [ text "Option 2" ]
                        , button [] [ text "Option 3" ]
                        ]
                ]
            ]

    myDropdownConfig : Dropdown.Config Msg
    myDropdownConfig =
        { identifier = "myDropdown"
        , toggleEvent = Dropdown.OnClick
        , drawerVisibleAttribute = class "visible"
        , onToggle = ToggleDropdown
        }


# Configuration

@docs State, Config, ToggleEvent


# Views

@docs dropdown, toggle, drawer

-}

import Html exposing (Attribute, Html, button, div, s, text)
import Html.Attributes exposing (attribute, id, property, style, tabindex)
import Html.Events exposing (custom, keyCode, on, onClick, onFocus, onMouseEnter, onMouseOut)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode


{-| Indicates wether the dropdown's drawer is visible or not.
-}
type alias State =
    Bool


{-| Configuration.

  - `identifier`: unique identifier for the dropdown.
  - `toggleEvent`: Event on which the dropdown's drawer should appear or disappear.
  - `drawerVisibleAttribute`: `Attribute msg` that's applied to the dropdown's drawer when visible.
  - `onToggle`: msg which will be called when the state of the dropdown should be changed.

-}
type alias Config msg =
    { identifier : String
    , toggleEvent : ToggleEvent
    , drawerVisibleAttribute : Attribute msg
    , onToggle : State -> msg
    }


{-| Used to set the event on which the dropdown's drawer should appear or disappear.
-}
type ToggleEvent
    = OnClick
    | OnHover
    | OnFocus


{-| Creates a dropdown using the given state, config, toggle, and drawer.

    dropdown
        myDropdownConfig
        myDropdownState
        div
        []
        [ toggle button
            [ class "myButton" ]
            [ text "More options" ]
        , drawer div
            [ class "myDropdownDrawer" ]
            [ button [ onClick NewFile ] [ text "New" ]
            , button [ onClick OpenFile ] [ text "Open..." ]
            , button [ onClick SaveFile ] [ text "Save" ]
            ]
        ]

-}
dropdown :
    { config | identifier : String, toggleEvent : ToggleEvent, onToggle : State -> msg }
    -> State
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List (Attribute msg)
    -> List ({ config | identifier : String, toggleEvent : ToggleEvent, onToggle : State -> msg } -> State -> Html msg)
    -> Html msg
dropdown ({ toggleEvent, identifier } as config) isOpen element attributes children =
    let
        toggleEvents =
            case toggleEvent of
                OnHover ->
                    [ on "mouseout" (handleFocusChanged config isOpen)
                    , on "focusout" (handleFocusChanged config isOpen)
                    ]

                _ ->
                    [ on "focusout" (handleFocusChanged config isOpen) ]
    in
    element
        ([ on "keydown" (handleKeyDown config isOpen) ]
            ++ toggleEvents
            ++ [ anchor identifier
               , tabindex -1
               , positionRelative
               , displayInlineBlock
               , outlineNone
               ]
            ++ attributes
        )
        (List.map (\child -> child config isOpen) children)


{-| Transforms the given HTML-element into a working toggle for your dropdown.
See `dropdown` on how to use in combination with `drawer`.

Example of use:

    toggle
        myDropdownConfig
        myDropdownState
        button
        [ class "myButton" ]
        [ text "More options" ]

-}
toggle :
    { config | onToggle : State -> msg, toggleEvent : ToggleEvent }
    -> State
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
toggle { onToggle, toggleEvent } isOpen element attributes children =
    let
        toggleEvents =
            case toggleEvent of
                OnClick ->
                    [ custom "click"
                        (Decode.succeed
                            { message = onToggle (not isOpen)
                            , preventDefault = True
                            , stopPropagation = True
                            }
                        )
                    ]

                OnHover ->
                    [ onMouseEnter (onToggle True)
                    , onFocus (onToggle True)
                    ]

                OnFocus ->
                    [ onFocus (onToggle True) ]
    in
    element
        (toggleEvents ++ attributes)
        children


{-| Transforms the given HTML-element into a working drawer for your dropdown.
See `dropdown` on how to use in combination with `toggle`.

Example of use:

    drawer
        div
        [ class "myDropdownDrawer" ]
        [ button [ onClick NewFile ] [ text "New" ]
        , button [ onClick OpenFile ] [ text "Open..." ]
        , button [ onClick SaveFile ] [ text "Save" ]
        ]

-}
drawer :
    { config | drawerVisibleAttribute : Attribute msg }
    -> State
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
drawer config isOpen element givenAttributes children =
    let
        attributes =
            if isOpen then
                config.drawerVisibleAttribute :: [ visibilityVisible, positionAbsolute ] ++ givenAttributes

            else
                [ visibilityHidden, positionAbsolute ] ++ givenAttributes
    in
    element
        attributes
        children


anchor : String -> Attribute msg
anchor identifier =
    property "dropdownId" (Encode.string identifier)


handleKeyDown :
    { config | identifier : String, onToggle : State -> msg }
    -> State
    -> Decoder msg
handleKeyDown { identifier, onToggle } isOpen =
    Decode.map onToggle
        (keyCode
            |> Decode.andThen
                (Decode.succeed << (&&) isOpen << not << (==) 27)
        )


handleFocusChanged :
    { config | identifier : String, onToggle : State -> msg }
    -> State
    -> Decoder msg
handleFocusChanged { identifier, onToggle } isOpen =
    Decode.map onToggle (isFocusOnSelf identifier)


isFocusOnSelf : String -> Decoder Bool
isFocusOnSelf identifier =
    Decode.field "relatedTarget" (decodeDomElement identifier)
        |> Decode.andThen isChildOfSelf
        |> Decode.withDefault False


decodeDomElement : String -> Decoder DomElement
decodeDomElement identifier =
    Decode.map2 DomElement
        (Decode.field "dropdownId" Decode.string
            |> Decode.andThen (isDropdown identifier)
            |> Decode.withDefault False
        )
        (Decode.field "parentElement"
            (Decode.lazy (\_ -> decodeDomElement identifier)
                |> Decode.map ParentElement
                |> Decode.maybe
            )
        )


isDropdown : String -> String -> Decoder Bool
isDropdown identifier identifier2 =
    Decode.succeed (identifier == identifier2)


isChildOfSelf : DomElement -> Decoder Bool
isChildOfSelf cfg =
    if cfg.isDropdown then
        Decode.succeed True

    else
        case cfg.parentElement of
            Nothing ->
                Decode.succeed False

            Just (ParentElement domElement) ->
                isChildOfSelf domElement


type alias DomElement =
    { isDropdown : Bool
    , parentElement : Maybe ParentElement
    }


type ParentElement
    = ParentElement DomElement


visibilityVisible : Attribute msg
visibilityVisible =
    style "visibility" "visible"


visibilityHidden : Attribute msg
visibilityHidden =
    style "visibility" "hidden"


positionRelative : Attribute msg
positionRelative =
    style "position" "relative"


positionAbsolute : Attribute msg
positionAbsolute =
    style "position" "absolute"


displayInlineBlock : Attribute msg
displayInlineBlock =
    style "display" "inline-block"


outlineNone : Attribute msg
outlineNone =
    style "outline" "none"
