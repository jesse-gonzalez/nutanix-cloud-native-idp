build {
    sources = [
        "source.nutanix.centos8"
    ]

    post-processor "manifest" {
      output = "manifest.json"
      strip_path = true
    }
}
