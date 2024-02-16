import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

class progressBar {
     JProgressBar progressBar;
     JPanel MainPanel;
     JButton cancelButton;
     JLabel Ratio;

    boolean cancelbuttonpushed;

    public progressBar() {
        cancelbuttonpushed = false;
        cancelButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                cancelbuttonpushed = true;
            }
        });
    }
}
