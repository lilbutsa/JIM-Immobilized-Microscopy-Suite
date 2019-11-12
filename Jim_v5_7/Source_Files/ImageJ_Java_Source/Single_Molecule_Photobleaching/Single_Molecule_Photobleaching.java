import ij.plugin.PlugIn;
import static javax.swing.WindowConstants.DISPOSE_ON_CLOSE;

/*James Walsh
This plugin generates intensity traces for a single channel data
*/

public class Single_Molecule_Photobleaching implements PlugIn {

    public void run(String arg) {
        
           // setup_Jim_Programs();
            
            SingleMolMainWindow mymainwindow = new SingleMolMainWindow();
            mymainwindow.setDefaultCloseOperation(DISPOSE_ON_CLOSE);
            mymainwindow.setVisible(true);
  
    }
    
   
    
}

