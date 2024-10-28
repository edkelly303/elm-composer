module DnD exposing (main)

import Browser
import Composer.Element
import DnDList
import Html
import Html.Attributes
import Process
import Task


fruits : List String
fruits =
    [ "Apples", "Bananas", "Cherries", "Dates" ]

type alias Components a = { dnd : a }

main :
    Program
        ()
        ( AppModel, ( DnDModel, () ) )
        ( Maybe AppMsg, ( Maybe DnDMsg, () ) )
main =
    Composer.Element.defineApp app_
        |> Composer.Element.addComponentWithRequirements
            dndList
            (\toApp appModel ->
                { items = appModel.fruits
                , itemsUpdated = toApp << ItemsUpdated
                }
            )
        |> Composer.Element.done Components
        |> Browser.element


type alias AppModel =
    { fruits : List String }


type AppMsg
    = ItemsUpdated (List String)


app_ =
    { init =
        \components toSelf flags ->
            ( { fruits = fruits }, Cmd.none )
    , update =
        \components toSelf msg model ->
            case msg of
                ItemsUpdated fruits_ ->
                    ( { model | fruits = fruits_ }, Cmd.none )
    , view =
        \components toSelf model ->
            Html.div []
                [ Html.p [] [ Html.text "This is the view of the `dndList` component:" ]
                , components.dnd.view model.fruits
                , Html.p [] [ Html.text "This is a `Debug.toString` of the list of items:" ]
                , Html.text (Debug.toString model.fruits)
                ]
    , subscriptions = 
        \components toSelf model -> Sub.none
    }


dndList =
    { interface =
        \toSelf model ->
            { view = view toSelf model }
    , init =
        \toSelf flags ->
            ( { dnd = system.model }
            , Cmd.none
            )
    , update =
        \app toSelf msg model ->
            case msg of
                DnDMsg dndMsg ->
                    let
                        ( dnd, newItems ) =
                            system.update dndMsg model.dnd app.items
                    in
                    ( { model | dnd = dnd }
                    , Cmd.batch
                        [ send (app.itemsUpdated newItems)
                        , Cmd.map toSelf (system.commands dnd)
                        ]
                    )
    , subscriptions =
        \app toSelf model ->
            subscriptions model
                |> Sub.map toSelf

    }


send msg =
    Task.perform identity (Task.succeed msg)


config : DnDList.Config String
config =
    { beforeUpdate = \_ _ list -> list
    , movement = DnDList.Free
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


system : DnDList.System String DnDMsg
system =
    DnDList.create config DnDMsg


type alias DnDModel =
    { dnd : DnDList.Model }


type DnDMsg
    = DnDMsg DnDList.Msg


subscriptions : DnDModel -> Sub DnDMsg
subscriptions model =
    system.subscriptions model.dnd


view toSelf model items =
    Html.section
        [ Html.Attributes.style "text-align" "center" ]
        [ items
            |> List.indexedMap (itemView model.dnd)
            |> Html.div []
        , ghostView model.dnd items
        ]
        |> Html.map toSelf


itemView : DnDList.Model -> Int -> String -> Html.Html DnDMsg
itemView dnd index item =
    let
        itemId : String
        itemId =
            "id-" ++ item
    in
    case system.info dnd of
        Just { dragIndex } ->
            if dragIndex /= index then
                Html.p
                    (Html.Attributes.id itemId :: system.dropEvents index itemId)
                    [ Html.text item ]

            else
                Html.p
                    [ Html.Attributes.id itemId ]
                    [ Html.text "[---------]" ]

        Nothing ->
            Html.p
                (Html.Attributes.id itemId :: system.dragEvents index itemId)
                [ Html.text item ]


ghostView : DnDList.Model -> List String -> Html.Html DnDMsg
ghostView dnd items =
    let
        maybeDragItem : Maybe String
        maybeDragItem =
            system.info dnd
                |> Maybe.andThen (\{ dragIndex } -> items |> List.drop dragIndex |> List.head)
    in
    case maybeDragItem of
        Just item ->
            Html.div
                (system.ghostStyles dnd)
                [ Html.text item ]

        Nothing ->
            Html.text ""
