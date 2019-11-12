import ij.plugin.PlugIn;
import static javax.swing.WindowConstants.DISPOSE_ON_CLOSE;

/*James Walsh
This plugin generates intensity traces for a single channel data
*/

public class Generate_Single_Channel_Trace implements PlugIn {

    public void run(String arg) {
        
           // setup_Jim_Programs();
            
            SingleMainWindow mymainwindow = new SingleMainWindow();
            mymainwindow.setDefaultCloseOperation(DISPOSE_ON_CLOSE);
            mymainwindow.setVisible(true);
  
    }
    
   
    
}

