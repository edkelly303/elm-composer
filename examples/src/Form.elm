module Form exposing (main)

import Browser
import Composer exposing (view)
import Composer.Element
import Dict exposing (Dict)
import Html
import Html.Attributes
import Html.Events
import Process
import Task
import Time


type alias User =
    { name : String, age : Int, cool : Bool, pet : Int }


type alias Pet =
    { id : Int, name : String }


main =
    Composer.Element.integrate formApp
        |> Composer.Element.withSimpleComponent (string "Name")
        |> Composer.Element.withSimpleComponent (int "Age")
        |> Composer.Element.withSimpleComponent (bool "Is cool?")
        |> Composer.Element.withSimpleComponent (select "Pet")
        |> Composer.Element.groupedAs
            (\name age cool petId ->
                { name = name
                , age = age
                , cool = cool
                , pet = petId
                }
            )
        |> Browser.element


pure =
    Ok


andMap statusArg resCtor =
    case ( statusArg, resCtor ) of
        ( Touched (Ok arg), Ok ctor ) ->
            Ok (ctor arg)

        ( Touched (Ok _), Err errs ) ->
            Err errs

        ( Touched (Err errs), Ok _ ) ->
            Err errs

        ( Touched (Err errs1), Err errs2 ) ->
            Err (errs2 ++ errs1)

        ( _, Err errs ) ->
            Err errs

        ( _, Ok _ ) ->
            Err []


map2 f status1 status2 =
    case ( status1, status2 ) of
        ( Touched (Ok arg1), Touched (Ok arg2) ) ->
            Touched (Ok (f arg1 arg2))

        ( Touched (Ok _), Touched (Err errs) ) ->
            Touched (Err errs)

        ( Touched (Err errs), Touched (Ok _) ) ->
            Touched (Err errs)

        ( Touched (Err errs1), Touched (Err errs2) ) ->
            Touched (Err (errs2 ++ errs1))

        ( _, _ ) ->
            Touched (Err [])


andThen2 f status1 status2 =
    case ( status1, status2 ) of
        ( Touched (Ok arg1), Touched (Ok arg2) ) ->
            Touched (f arg1 arg2)

        ( Touched (Ok _), Touched (Err errs) ) ->
            Touched (Err errs)

        ( Touched (Err errs), Touched (Ok _) ) ->
            Touched (Err errs)

        ( Touched (Err errs1), Touched (Err errs2) ) ->
            Touched (Err (errs2 ++ errs1))

        ( _, _ ) ->
            Touched (Err [])


type AppMsg
    = SubmitClicked
    | BackClicked


type AppModel
    = FormActive
    | Success User


formApp =
    let
        validate name age cool pet =
            pure (\n { a, c } p -> User n a c p)
                |> andMap name.parsed
                |> andMap
                    (andThen2
                        (\a c ->
                            if c && a > 40 then
                                Err [ ( "Is cool?", String.fromInt a ++ " is too old to be cool" ) ]

                            else
                                Ok { a = a, c = c }
                        )
                        age.parsed
                        cool.parsed
                    )
                |> andMap pet.parsed
    in
    { init =
        \{} _ () ->
            ( FormActive, Cmd.none )
    , update =
        \{ name, age, cool, pet } _ msg model ->
            case msg of
                SubmitClicked ->
                    case validate name age cool pet of
                        Ok user ->
                            ( Success user
                            , Cmd.batch
                                [ send name.reset
                                , send age.reset
                                , send cool.reset
                                , send pet.reset
                                ]
                            )

                        Err errs ->
                            ( FormActive
                            , Cmd.batch
                                [ send name.touch
                                , send age.touch
                                , send pet.touch
                                ]
                            )

                BackClicked ->
                    ( FormActive
                    , Cmd.none
                    )
    , view =
        \{ name, age, cool, pet } toSelf model ->
            case model of
                FormActive ->
                    let
                        errs =
                            case validate name age cool pet of
                                Err errs_ ->
                                    errs_

                                Ok _ ->
                                    []
                    in
                    Html.form []
                        [ Html.h1 [] [ Html.text "Create a user" ]
                        , name.view errs
                        , age.view errs
                        , cool.view errs
                        , pet.view
                            .id
                            (\pet_ -> Html.text pet_.name)
                            [ { id = 1, name = "Fido" }, { id = 2, name = "Miaowcus" } ]
                            errs
                        , Html.button
                            [ Html.Attributes.type_ "button"
                            , Html.Events.onClick (toSelf SubmitClicked)
                            ]
                            [ Html.text "Submit!" ]
                        ]

                Success user ->
                    Html.div []
                        [ Html.text ("Hello " ++ user.name)
                        , Html.button
                            [ Html.Attributes.type_ "button"
                            , Html.Events.onClick (toSelf BackClicked)
                            ]
                            [ Html.text "Go back!" ]
                        ]
    , subscriptions =
        \{} _ model ->
            Sub.none
    }


send msg =
    Task.perform identity (Task.succeed msg)


string label =
    textInput
        (\str ->
            if String.isEmpty str then
                Err [ ( label, "Name must not be blank" ) ]

            else
                Ok str
        )
        label


int label =
    textInput
        (\str ->
            case String.toInt str of
                Just i ->
                    Ok i

                Nothing ->
                    Err [ ( label, "Age must be an integer" ) ]
        )
        label


type TextInputMsg
    = StringChanged String
    | Touch
    | Reset
    | DebounceStarted Time.Posix
    | DebounceChecked Time.Posix


type InputStatus parsed
    = Intact
    | Debouncing Time.Posix
    | Touched (Result (List ( String, String )) parsed)


type SelectInputMsg a
    = Select_Selected (Maybe a)
    | Select_Touch
    | Select_Reset


select label =
    let
        parse selected =
            Touched (Result.fromMaybe [ ( label, "Must select an option" ) ] selected)

        init =
            ( { selected = Nothing, parsed = Intact }, Cmd.none )
    in
    { interface =
        \toSelf model ->
            { view =
                \toId toHtml items errs ->
                    let
                        ( icon, message ) =
                            viewFeedback label model.parsed errs
                    in
                    Html.div []
                        [ Html.strong []
                            [ Html.text label ]
                        , Html.div []
                            [ Html.span []
                                (List.map
                                    (\item ->
                                        let
                                            id =
                                                toId item

                                            isChecked =
                                                model.selected == Just id
                                        in
                                        Html.label []
                                            [ Html.input
                                                [ Html.Attributes.type_ "radio"
                                                , Html.Attributes.name "radio"
                                                , Html.Attributes.checked isChecked
                                                , Html.Events.onCheck
                                                    (\nowChecked ->
                                                        toSelf
                                                            (Select_Selected
                                                                (if nowChecked then
                                                                    Just id

                                                                 else
                                                                    Nothing
                                                                )
                                                            )
                                                    )
                                                ]
                                                []
                                            , toHtml item
                                            ]
                                    )
                                    items
                                )
                            , Html.text icon
                            ]
                        , Html.small [] [ Html.text message ]
                        ]
            , selected = model.selected
            , parsed = model.parsed
            , reset = toSelf Select_Reset
            , touch = toSelf Select_Touch
            }
    , init =
        \flags ->
            init
    , update =
        \msg model ->
            case msg of
                Select_Selected selection ->
                    ( { model | selected = selection, parsed = parse selection }, Cmd.none )

                Select_Touch ->
                    ( { model | parsed = parse model.selected }, Cmd.none )

                Select_Reset ->
                    init
    , subscriptions =
        \model ->
            Sub.none
    }


bool label =
    { interface =
        \toSelf model ->
            let
                parse m =
                    Touched (Ok m)
            in
            { view =
                \errs ->
                    let
                        ( icon, message ) =
                            viewFeedback label (parse model) errs
                    in
                    Html.div []
                        [ Html.label []
                            [ Html.strong [] [ Html.text label ]
                            , Html.input
                                [ Html.Attributes.type_ "checkbox"
                                , Html.Attributes.checked model
                                , Html.Events.onCheck (\_ -> toSelf (not model))
                                ]
                                []
                            ]
                        , Html.small [] [ Html.text message ]
                        ]
            , parsed = parse model
            , reset = toSelf False
            }
    , init =
        \flags ->
            ( False, Cmd.none )
    , update =
        \msg model ->
            ( msg, Cmd.none )
    , subscriptions =
        \model ->
            Sub.none
    }


textInput parse label =
    let
        init =
            ( { value = ""
              , status = Intact
              }
            , Cmd.none
            )
    in
    { interface =
        \toSelf model ->
            { view = \errs -> textInputView label model errs |> Html.map toSelf
            , parsed = model.status
            , touch = toSelf Touch
            , reset = toSelf Reset
            }
    , init =
        \flags ->
            init
    , update =
        \msg model ->
            case msg of
                StringChanged str ->
                    ( { model | value = str }
                    , Task.perform DebounceStarted Time.now
                    )

                Reset ->
                    init

                Touch ->
                    ( { model
                        | status =
                            case model.status of
                                Touched _ ->
                                    model.status

                                _ ->
                                    Touched (parse model.value)
                      }
                    , Cmd.none
                    )

                DebounceStarted now ->
                    ( { model | status = Debouncing now }
                    , Task.perform (\() -> DebounceChecked now) (Process.sleep 500)
                    )

                DebounceChecked now ->
                    ( case model.status of
                        Debouncing current ->
                            if now == current then
                                { model | status = Touched (parse model.value) }

                            else
                                model

                        _ ->
                            model
                    , Cmd.none
                    )
    , subscriptions =
        \model ->
            Sub.none
    }


textInputView label { value, status } errs =
    let
        ( icon, message ) =
            viewFeedback label status errs
    in
    Html.div []
        [ Html.label []
            [ Html.strong [] [ Html.text label ]
            , Html.div []
                [ Html.input
                    [ Html.Events.onInput StringChanged
                    , Html.Attributes.value value
                    ]
                    []
                , Html.text icon
                ]
            , Html.small [] [ Html.text message ]
            ]
        ]


viewFeedback label status errs =
    let
        relevantErrs =
            errs
                |> List.filterMap
                    (\( key, val ) ->
                        if key == label then
                            Just val

                        else
                            Nothing
                    )
    in
    case status of
        Intact ->
            ( "", "" )

        Touched parsed ->
            case ( parsed, relevantErrs ) of
                ( Ok p, [] ) ->
                    ( " ✅", "" )

                ( Ok _, _ ) ->
                    ( " 🚫"
                    , String.join "\n" relevantErrs
                    )

                ( Err e, _ ) ->
                    ( " 🚫"
                    , String.join "\n"
                        (List.map Tuple.second e ++ relevantErrs)
                    )

        Debouncing _ ->
            ( " ⌨️", "" )
