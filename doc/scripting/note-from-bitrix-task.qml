import QtQml 2.0
import com.qownnotes.noteapi 1.0

/**
 * This script creates a menu item and a button that parses the text that was copied 
 * from a task webpage of the webservice bitrix24 and creates a new note with a headline,
 * the link to the task and the description
 */
QtObject {
    /**
     * Initializes the custom action
     */
    function init() {
        // create a menu entry "New Bitrix note" with a button and a freedesktop theme icon
        script.registerCustomAction("newBitrixTaskNote", "New Bitrix task note", "Bitrix", "task-new");
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     * 
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        switch (identifier) {
            // create a new note from a Bitrix task webpage text in the clipboard
            // like from https://yourname.bitrix24.com/workgroups/group/10/tasks/task/view/150/
            case "newBitrixTaskNote":
                // get the text that is currently in the clipboard
                var html = script.clipboard(true);

//                script.log(html);

                // https://regex101.com is your friend
//                 var headlineRegExp = /<span class="pagetitle-inner".*?>(.+?)<\/span>/im;
                var headlineRegExp = /<span id="pagetitle".*?>(.+?)<\/span>/im;
                var headlineMatch = headlineRegExp.exec(html);
                var headline = headlineMatch !== null ? headlineMatch[1] : "";
                // remove the "aufgabe" text and all "/"
                headline = headline.replace("(aufgabe #", "(#").replace(/\s*\//igm, "");

                if (headline == "") {
                    script.log("No Bitrix task headline was found!");
                    return;
                }

                var descriptionRegExp = /<div.*? id="task-detail-description".*?>(.+?)<\/div>/im;
                var descriptionMatch = descriptionRegExp.exec(html);
                var description = descriptionMatch !== null ? descriptionMatch[1] : "";
                // transform html breaks to \n and remove all other tags
                description = description.replace(/<br.*?>/gim, "\n").replace(/<.+?>/gim, "");

//                 var urlRegExp = /<form name="COMMENTS_.+?".*? action="(.+?)" method/im;
                var urlRegExp = /<a href="(.+?)[\?#].*?" class="main-buttons-item-link"/im;
                var urlMatch = urlRegExp.exec(html);
                var url = urlMatch !== null ? urlMatch[1] : "";

//                script.log(headline);
//                script.log(descriptionMatch);
//                script.log(description);
//                script.log(url);

                // add the headline of the task
                var text = headline + "\n";

                // add "=" characters so that the headline is really a headline
                for (var i = 0; i < headline.length; i++) {
                    text += "=";
                }

                // add the url to the task
                if (url != "") {
                    text += "\n\n- <" + url + ">";
                }

                // add the description of the task
                if (description != "") {
                    text += "\n\n" + description;
                }

                text = text.replace("&gt;", ">").replace("&lt;", "<");

                // add a date headline
                var m = new Date();
                var dateString =
                    ("0" + m.getDate()).slice(-2) + "." +
                    ("0" + (m.getMonth()+1)).slice(-2) + "." +
                    m.getFullYear();
                text += "\n\n## " + dateString + "\n\n";

                // create a new note
                script.createNote(text);

                // tag the current note
                script.tagCurrentNote("todo");

                break;
        }

        // workaround because the parsers don't seem to work every time
        script.reloadScriptingEngine();
    }
}
