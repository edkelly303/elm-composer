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
        |> Composer.Element.run


type alias AppModel =
    { fruits : List String }


type AppMsg
    = ItemsUpdated (List String)


app_ =
    { init =
        \toSelf flags ->
            ( { fruits = fruits }, Cmd.none )
    , update =
        \dnd toSelf msg model ->
            case msg of
                ItemsUpdated fruits_ ->
                    ( { model | fruits = fruits_ }, Cmd.none )
    , view =
        \dnd toSelf model ->
            Html.div []
                [ Html.p [] [ Html.text "This is the view of the `dndList` component:" ]
                , dnd.view
                , Html.p [] [ Html.text "This is a `Debug.toString` of the list of items:" ]
                , Html.text (Debug.toString model.fruits)
                ]
    , subscriptions = \dnd toSelf model -> Sub.none
    }


dndList =
    { init =
        -- slightly modified the DnDList's `init` function to allow us to pass
        -- in the list of items during initialisation.
        \app toSelf flags ->
            ( { dnd = system.model }
            , Cmd.none
            )
    , update =
        -- slightly modified the `update` function to send an `AppMsg` to the
        -- user's app whenever the list of items changes.
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
    , interface =
        \app toSelf model ->
            { view = view app toSelf model }
    , subscriptions =
        -- `subscriptions` is exactly the same, we just need to map the `Sub msg`
        \app toSelf model ->
            subscriptions model
                |> Sub.map toSelf
    }

send msg = 
    Task.perform identity (Task.succeed msg)

-- All the code from this point on is _exactly_ the same as it is in the DnDList docs


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


view app toSelf model =
    Html.section
        [ Html.Attributes.style "text-align" "center" ]
        [ app.items
            |> List.indexedMap (itemView model.dnd)
            |> Html.div []
        , ghostView model.dnd app.items
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
