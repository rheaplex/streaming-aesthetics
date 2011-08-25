/*******************************************************************************
  Global state
*******************************************************************************/

// The user's Twitter account login details
String twitterUser;
String twitterPassword;
String query;

/*******************************************************************************
  Twitter User Details
*******************************************************************************/

// Java is designed to produce this kind of busy-work

class ConfigurationDialog extends JDialog implements ActionListener
{
  JLabel usernameLabel;
  JLabel passwordLabel;
  JTextField usernameField;
  JPasswordField passwordField;
  JCheckBox fullscreenCheck;
  JButton okButton;
  
  JDialog dlg;
  
  boolean okButtonPressed;
  
  public ConfigurationDialog() {
    JPanel usernamePanel = new JPanel();
    usernameLabel = new JLabel("Twitter Account Username:");
    usernameField = new JTextField (10);
    usernamePanel.add(usernameLabel);
    usernamePanel.add(usernameField);
  
    JPanel passwordPanel = new JPanel();
    passwordLabel = new JLabel("Twitter Account Password:");
    passwordField = new JPasswordField(10);
    passwordPanel.add(passwordLabel);
    passwordPanel.add(passwordField);
    
    JPanel fullscreenPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    fullscreenCheck = new JCheckBox("Full Screen");
    fullscreenPanel.add(fullscreenCheck);
  
    JPanel okPanel = new JPanel();
    okButton = new JButton("OK");
    okButton.addActionListener(this);
    okPanel.add(okButton);
  
    dlg = new JDialog();
    dlg.setModalityType (Dialog.ModalityType.APPLICATION_MODAL);
    dlg.setResizable(false);
    dlg.getContentPane().setLayout(new GridLayout (4, 1));
    dlg.getContentPane().add(usernamePanel);
    dlg.getContentPane().add(passwordPanel);
    dlg.getContentPane().add(fullscreenPanel);
    dlg.getContentPane().add(okPanel);
    dlg.getRootPane().setDefaultButton(okButton);
    dlg.setTitle("Configure");
    dlg.pack();
    dlg.setLocationRelativeTo(null);
    dlg.setVisible(true);
  }
  
  public void actionPerformed (ActionEvent ae)
  {
    // This assumes every action is a confirmation action
    if (ae.getSource() == okButton) {
      okButtonPressed = true; 
      twitterUser = usernameField.getText();
      twitterPassword = passwordField.getText();
      fullscreen = fullscreenCheck.isSelected();
    }
    dlg.dispose();
  }
  
  public boolean configured () {
    return okButtonPressed;
  }
}

// Read the configuration from a properties file

Properties getConfigurationProperties () {
  Properties properties = new Properties();
  InputStream propStream = openStream("./twitter.properties");
  if (propStream != null) {
    try {
      properties.load(propStream);
    } catch (IOException e) {
      // Make sure the properties object is empty & coherent if load failed
      properties = new Properties();
    }
  }
  return properties;
}

// Configure from a properties file rather than the GUI
// This is for development or exhibition rather than online

boolean configureFromProperties () {
  boolean configured = false;
  Properties p = getConfigurationProperties();
  if((p != null) && (p.containsKey("username")) && p.containsKey("password")) {
    twitterUser = (String)p.getProperty("username");
    twitterPassword = (String)p.getProperty("password");
    if(p.containsKey("fullscreen")) {
      fullscreen = ((String)p.getProperty("fullscreen", "false").toLowerCase()) == "true";
    }
    configured = true;
  }
  return configured;
}

