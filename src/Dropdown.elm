module Dropdown exposing
    ( State, Config, ToggleEvent(..)
    , dropdown, toggle, drawer
    , root
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
                , isToggled = myDropdownIsOpen
                }
            ]


# Configuration

@docs State, Config, ToggleEvent


# Views

@docs dropdown, root, toggle, drawer

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
    , layout : Builder msg -> html
    , isToggled : State
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
type alias Builder msg =
    { toDropdown : HtmlBuilder msg -> HtmlBuilder msg
    , toToggle : HtmlBuilder msg -> HtmlBuilder msg
    , toDrawer : HtmlBuilder msg -> HtmlBuilder msg
    }


{-| The convenient way of building a dropdown. Everything can be done with this one function.

Use the `Dropdown.Builder` that is provided in order to layout the elements of the dropdown however you wish.

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
        , isToggled = myDropdownState
        }

-}
dropdown :
    Config msg html
    -> html
dropdown config =
    config.layout
        { toToggle = toggle config
        , toDrawer = drawer config
        , toDropdown = root config
        }


{-| An alternative way to roll your own dropdown using the given config, isToggled, toggle, and drawer.

    type alias SimpleDropdownConfig msg =
        { identifier : String
        , toggleEvent : ToggleEvent
        , drawerVisibleAttribute : Attribute msg
        , onToggle : State -> msg
        , isToggled : State
        , toggleAttrs : List (Attribute msg)
        , toggleLabel : Html msg
        , drawerAttrs : List (Attribute msg)
        , drawerItems : List (Html msg)
        }

    simpleDropdown : SimpleDropdownConfig msg -> Html msg
    simpleDropdown config =
        root config
            div
            []
            [ toggle config button config.toggleAttrs [ config.toggleLabel ]
            , drawer config div config.drawerAttrs config.drawerItems
            ]

-}
root :
    { config | identifier : String, toggleEvent : ToggleEvent, onToggle : State -> msg, isToggled : State }
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
root { toggleEvent, identifier, onToggle, isToggled } element attributes children =
    let
        toggleEvents =
            case toggleEvent of
                OnHover ->
                    [ on "mouseout" handleFocusChanged
                    , on "focusout" handleFocusChanged
                    ]

                _ ->
                    [ on "focusout" handleFocusChanged ]

        handleKeyDown =
            Decode.map onToggle
                (keyCode
                    |> Decode.andThen
                        (Decode.succeed << (&&) isToggled << not << (==) 27)
                )

        handleFocusChanged =
            Decode.map onToggle (isFocusOnSelf identifier)
    in
    element
        ([ on "keydown" handleKeyDown ]
            ++ toggleEvents
            ++ [ property "dropdownId" (Encode.string identifier)
               , tabindex -1
               , style "position" "relative"
               , style "display" "inline-block"
               , style "outline" "none"
               ]
            ++ attributes
        )
        children


{-| Transforms the given HTML-element into a working toggle for your dropdown.
See `dropdown` on how to use in combination with `drawer`.

Example of use:

    toggle
        { onToggle = DropdownToggle, toggleEvent = Dropdown.OnClick, isToggled = myDropdownIsOpen }
        myDropdownState
        button
        [ class "myButton" ]
        [ text "More options" ]

-}
toggle :
    { config | onToggle : State -> msg, toggleEvent : ToggleEvent, isToggled : State }
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
toggle { onToggle, toggleEvent, isToggled } element attributes children =
    let
        toggleEvents =
            case toggleEvent of
                OnClick ->
                    [ custom "click"
                        (Decode.succeed
                            { message = onToggle (not isToggled)
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
        { drawerVisibleAttribute = class "visible", isToggled = myDropdownIsOpen }
        div
        [ class "myDropdownDrawer" ]
        [ button [ onClick NewFile ] [ text "New" ]
        , button [ onClick OpenFile ] [ text "Open..." ]
        , button [ onClick SaveFile ] [ text "Save" ]
        ]

-}
drawer :
    { config | drawerVisibleAttribute : Attribute msg, isToggled : State }
    -> (List (Attribute msg) -> List (Html msg) -> Html msg)
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
drawer { drawerVisibleAttribute, isToggled } element givenAttributes children =
    let
        attributes =
            if isToggled then
                drawerVisibleAttribute :: [ style "visibility" "visible", style "position" "absolute" ] ++ givenAttributes

            else
                [ style "visibility" "hidden", style "position" "absolute" ] ++ givenAttributes
    in
    element
        attributes
        children


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
