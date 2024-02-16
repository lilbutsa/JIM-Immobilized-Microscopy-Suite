
package org.micromanager.plugins.Poor_Mans_JIM;


import org.micromanager.MenuPlugin;
import org.micromanager.Studio;

import org.scijava.plugin.Plugin;
import org.scijava.plugin.SciJavaPlugin;

import javax.swing.*;

@Plugin(type = MenuPlugin.class)
public class Jimbob implements SciJavaPlugin, MenuPlugin {
    private Studio studio_;
    // private FeedbackFrame frame_;

    private JFrame frame;

    /**
     * This method receives the Studio object, which is the gateway to the
     * Micro-Manager API. You should retain a reference to this object for the
     * lifetime of your plugin. This method should not do anything except for
     * store that reference, as Micro-Manager is still busy starting up at the
     * time that this is called.
     */
    @Override
    public void setContext(Studio studio) {
        studio_ = studio;
    }

    /**
     * This method is called when your plugin is selected from the Plugins menu.
     * Typically at this time you should show a GUI (graphical user interface)
     * for your plugin.
     */
    @Override
    public void onPluginSelected() {
        frame = new JFrame("Jimbob");
        frame.setContentPane(new PMJ_Window(studio_).MainPanel);
        frame.setDefaultCloseOperation(JFrame.HIDE_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);
    }

    /**
     * This string is the sub-menu that the plugin will be displayed in, in the
     * Plugins menu.
     */
    @Override
    public String getSubMenu() {
        return "";
    }

    /**
     * The name of the plugin in the Plugins menu.
     */
    @Override
    public String getName() {
        return "Jimbob";
    }

    @Override
    public String getHelpText() {
        return "Jim but only the basics.";
    }

    @Override
    public String getVersion() {
        return "1.0";
    }

    @Override
    public String getCopyright() {
        return "UNSW 2023";
    }
}
