import ij.plugin.PlugIn;

import javax.swing.*;

/*James Walsh
This plugin generates intensity traces for immobilized fluorescent data
*/


public class Begin_Here_Generate_Traces implements PlugIn {

    private JFrame frame;

    public void run(String arg) {

        frame = new JFrame("JIM - Generate Traces");
        frame.setContentPane(new GenerateTracesWindow().mainPanel);
        frame.setDefaultCloseOperation(JFrame.HIDE_ON_CLOSE);
        frame.pack();
        frame.setVisible(true);


    }

}

