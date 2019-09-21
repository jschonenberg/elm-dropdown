module Dropdown exposing
    ( State, Config, ToggleEvent(..)
    , dropdown, root, toggle, drawer
    )

{-| Flexible dropdown component which serves as a foundation for custom dropdowns, select–inputs, popovers, and more.


# Example

Basic example of usage:

    init : Model
    init =
        { myDropdownIsOpen = False }

    type alias Model =
        { myDropdownIsOpen : Dropdown.State }

    type Msg
        = ToggleDropdown Bool

    update : Msg -> Model -> Model
    update msg model =
        case msg of
            ToggleDropdown newState ->
                { model | myDropdownIsOpen = newState }

    view : Model -> Html Msg
    view { myDropdownIsOpen } =
        div []
            [ dropdown
                { identifier = "my-dropdown"
                , toggleEvent = Dropdown.OnClick
                , drawerVisibleAttribute = class "visible"
                , onToggle = ToggleDropdown
                , layout =
                    \{ toDropdown, toToggle, toDrawer } ->
                        toDropdown div
                            []
                            [ toToggle button [] [ text "Toggle" ]
                            , toDrawer div
                                []
                                [ button [] [ text "Option 1" ]
                                , button [] [ text "Option 2" ]
                                , button [] [ text "Option 3" ]
                                ]
                            ]
                }
                myDropdownIsOpen
            ]


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
  - `layout`: The layout function that determines how the elements of the dropdown should be layed out.

-}
type alias Config msg html =
    { identifier : String
    , toggleEvent : ToggleEvent
    , drawerVisibleAttribute : Attribute msg
    , onToggle : State -> msg
    , layout : DropdownBuilder msg -> html
    }


{-| Used to set the event on which the dropdown's drawer should appear or disappear.
-}
type ToggleEvent
    = OnClick
    | OnHover
    | OnFocus


{-| A shorthand for the type of function used to construct Html element nodes.

This takes a list of attributes and a list of child elements in order to build a new parent element.

-}
type alias HtmlBuilder msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


{-| Everything required to build a particular dropdown.

  - toDropdown - the function `root` with `Config` and `State` applied to it.
  - toToggle - the function `toggle` with `Config` and `State` applied to it.
  - toDrawer - the function `drawer` with `Config` and `State` applied to it.

-}
type alias DropdownBuilder msg =
    { toDropdown : HtmlBuilder msg -> HtmlBuilder msg
    , toToggle : HtmlBuilder msg -> HtmlBuilder msg
    , toDrawer : HtmlBuilder msg -> HtmlBuilder msg
    }


{-| The convenient way of building a dropdown. Everything can be done with this one function.

Use the `DropdownBuilder` that is provided in order to layout the elements of the dropdown however you wish.

    Dropdown.dropdown
        { identifier = "my-dropdown"
        , toggleEvent = Dropdown.OnClick
        , drawerVisibleAttribute = class "visible"
        , onToggle = ToggleDropdown
        , layout =
            \{ toDropdown, toToggle, toDrawer } ->
                toDropdown div
                    []
                    [ toToggle button [] [ text "Toggle" ]
                    , toDrawer div
                        []
                        [ button [] [ text "Option 1" ]
                        , button [] [ text "Option 2" ]
                        , button [] [ text "Option 3" ]
                        ]
                    ]
        }
        myDropdownState

-}
dropdown :
    Config msg html
    -> State
    -> html
dropdown config state =
    config.layout
        { toToggle = toggle config state
        , toDrawer = drawer config state
        , toDropdown = root config state
        }


{-| An alternative way to roll your own dropdown using the given config, state, toggle, and drawer.

    type alias SimpleDropdownConfig msg =
        { identifier : String
        , toggleEvent : ToggleEvent
        , drawerVisibleAttribute : Attribute msg
        , onToggle : State -> msg
        , toggleAttrs : List (Attribute msg)
        , toggleLabel : Html msg
        , drawerAttrs : List (Attribute msg)
        , drawerItems : List (Html msg)
        }

    simpleDropdown : SimpleDropdownConfig msg -> State -> Html msg
    simpleDropdown config state =
        root config
            state
            div
            []
            [ toggle config state button config.toggleAttrs [ config.toggleLabel ]
            , drawer config state div config.drawerAttrs config.drawerItems
            ]

-}
root :
    { config | identifier : String, toggleEvent : ToggleEvent, onToggle : State -> msg }
    -> State
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
root ({ toggleEvent, identifier } as config) isOpen element attributes children =
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
        children


{-| Transforms the given HTML-element into a working toggle for your dropdown.
See `dropdown` on how to use in combination with `drawer`.

Example of use:

    toggle
        { onToggle = DropdownToggle, toggleEvent = Dropdown.OnClick }
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
        { drawerVisibleAttribute = class "visible" }
        dropdownState
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
