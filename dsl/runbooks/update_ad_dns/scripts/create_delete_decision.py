if '@@{update_type}@@' == 'Create':
    print "Requested DNS Update Type: @@{update_type}@@"
    exit(0)
elif '@@{update_type}@@' == 'Delete':
    print "Requested DNS Update Type: @@{update_type}@@"
    exit(1)
