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
    Browser.element program


program =
    Composer.Element.defineApp app
        |> Composer.Element.addComponent
            (dndList
                { items = fruits
                , itemsUpdated = ItemsUpdated
                }
            )
        |> Composer.Element.done


type alias AppModel =
    -- our `AppModel` knows _nothing at all_ about the `DnDList`; all it
    -- contains is the list of items.
    List String


type AppMsg
    = ItemsUpdated (List String)


app =
    { init = \sendToDnD sendToSelf flags -> ( fruits, Cmd.none )
    , update =
        \sendToDnD sendToSelf msg model ->
            case msg of
                ItemsUpdated items ->
                    ( items, Cmd.none )
    , view =
        \viewDnD sendToDnD sendToSelf model ->
            Html.div []
                [ Html.p [] [ Html.text "This is the view of the `dndList` component:" ]
                , viewDnD
                , Html.p [] [ Html.text "This is a `Debug.toString` of the `AppModel`:" ]
                , Html.text (Debug.toString model)
                ]
    , subscriptions = \sendToDnD sendToSelf model -> Sub.none
    }


dndList { items, itemsUpdated } =
    { init =
        -- slightly modified the DnDList's `init` function to allow us to pass
        -- in the list of items during initialisation.
        \sendToApp sendToSelf flags ->
            ( { dnd = system.model
              , items = items
              }
            , Cmd.none
            )
    , update =
        -- slightly modified the `update` function to send an `AppMsg` to the
        -- user's app whenever the list of items changes.
        \sendToApp sendToSelf msg model ->
            case msg of
                DnDMsg dndMsg ->
                    let
                        ( dnd, newItems ) =
                            system.update dndMsg model.dnd model.items
                    in
                    ( { model | dnd = dnd, items = newItems }
                    , Cmd.batch
                        [ Cmd.map sendToSelf (system.commands dnd)
                        , Task.perform (\_ -> sendToApp (itemsUpdated newItems)) (Process.sleep 0)
                        ]
                    )
    , view =
        -- `view` is exactly the same, we just need to map the `Html msg`
        \sendToApp sendToSelf model ->
            view model
                |> Html.map sendToSelf
    , subscriptions =
        -- `subscriptions` is exactly the same, we just need to map the `Sub msg`
        \sendToApp sendToSelf model ->
            subscriptions model
                |> Sub.map sendToSelf
    }



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
    { dnd : DnDList.Model
    , items : List String
    }


type DnDMsg
    = DnDMsg DnDList.Msg


subscriptions : DnDModel -> Sub DnDMsg
subscriptions model =
    system.subscriptions model.dnd


view : DnDModel -> Html.Html DnDMsg
view model =
    Html.section
        [ Html.Attributes.style "text-align" "center" ]
        [ model.items
            |> List.indexedMap (itemView model.dnd)
            |> Html.div []
        , ghostView model.dnd model.items
        ]


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
