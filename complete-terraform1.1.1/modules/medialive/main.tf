terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# MediaLive Input (RTMP Push)
resource "aws_medialive_input" "rtmp" {
  name                  = "${var.project_name}-${var.environment}-rtmp-input"
  type                  = "RTMP_PUSH"
  input_security_groups = [var.security_group_id]

  destinations {
    stream_name = "stream-key-1"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-rtmp-input"
    }
  )
}

# Video Encode 설정
locals {
  video_settings = {
    "1080p" = { width = 1920, height = 1080, bitrate = 5000000 }
    "720p"  = { width = 1280, height = 720,  bitrate = 3000000 }
    "480p"  = { width = 854,  height = 480,  bitrate = 1500000 }
  }
  selected_video = local.video_settings[var.video_quality]
}

# MediaLive Channel
resource "aws_medialive_channel" "main" {
  name          = "${var.project_name}-${var.environment}-channel"
  channel_class = var.channel_class
  role_arn      = var.iam_role_arn

  input_specification {
    codec            = "AVC"
    input_resolution = var.video_quality == "1080p" ? "HD" : "SD"
    maximum_bitrate  = "MAX_10_MBPS"
  }

  input_attachments {
    input_attachment_name = "main-input"
    input_id              = aws_medialive_input.rtmp.id
  }

  # S3 HLS 출력
  destinations {
    id = "s3-hls"

    settings {
      url = "s3://${var.hls_bucket_name}/"
    }
  }

  # Archive 출력 (선택사항)
  dynamic "destinations" {
    for_each = var.enable_archive && var.archive_bucket_name != "" ? [1] : []
    content {
      id = "s3-archive"

      settings {
        url = "s3://${var.archive_bucket_name}/archive"
      }
    }
  }

  encoder_settings {
    timecode_config {
      source = "EMBEDDED"
    }

    audio_descriptions {
      audio_selector_name = "default"
      codec_settings {
        aac_settings {
          bitrate         = 128000
          coding_mode     = "CODING_MODE_2_0"
          input_type      = "NORMAL"
          profile         = "LC"
          rate_control_mode = "CBR"
          sample_rate     = 48000
          spec            = "MPEG4"
        }
      }
      name = "audio_1"
    }

    video_descriptions {
      name = "video_${var.video_quality}"
      
      codec_settings {
        h264_settings {
          adaptive_quantization = "HIGH"
          bitrate              = local.selected_video.bitrate
          framerate_control    = "SPECIFIED"
          framerate_numerator  = 30
          framerate_denominator = 1
          gop_b_reference      = "DISABLED"
          gop_closed_cadence   = 1
          gop_num_b_frames     = 2
          gop_size             = 60
          gop_size_units       = "FRAMES"
          level                = "H264_LEVEL_AUTO"
          look_ahead_rate_control = "HIGH"
          num_ref_frames       = 1
          par_control          = "SPECIFIED"
          profile              = "HIGH"
          rate_control_mode    = "CBR"
          scan_type            = "PROGRESSIVE"
          scene_change_detect  = "ENABLED"
          syntax               = "DEFAULT"
        }
      }

      height = local.selected_video.height
      width  = local.selected_video.width
    }

    # HLS 출력 그룹
    output_groups {
      name = "S3_HLS"

      output_group_settings {
        hls_group_settings {
          ad_markers                = []
          caption_language_setting  = "OMIT"
          client_cache              = "ENABLED"
          codec_specification       = "RFC_4281"
          directory_structure       = "SINGLE_DIRECTORY"
          destination {
            destination_ref_id = "s3-hls"
          }


          hls_cdn_settings {
            hls_basic_put_settings {
              connection_retry_interval = 1
              filecache_duration        = 300
              num_retries               = 10
              restart_delay             = 15
            }
          }
          hls_id3_segment_tagging  = "DISABLED"
          index_n_segments         = 10
          input_loss_action        = "EMIT_OUTPUT"
          iv_in_manifest           = "INCLUDE"
          iv_source                = "FOLLOWS_SEGMENT_NUMBER"
          keep_segments            = 21
          manifest_compression     = "NONE"
          manifest_duration_format = "FLOATING_POINT"
          mode                     = "LIVE"
          output_selection         = "MANIFESTS_AND_SEGMENTS"
          program_date_time_period = 600
          program_date_time        = "INCLUDE"
          redundant_manifest       = "DISABLED"
          segment_length           = 6
          segments_per_subdirectory = 10000
          stream_inf_resolution    = "INCLUDE"
          timed_metadata_id3_frame = "PRIV"
          timed_metadata_id3_period = 10
          ts_file_mode             = "SEGMENTED_FILES"
        }
      }

      outputs {
        audio_description_names = ["audio_1"]
        output_name             = var.video_quality
        output_settings {
          hls_output_settings {
            hls_settings {
              standard_hls_settings {
                audio_rendition_sets = "PROGRAM_AUDIO"
                m3u8_settings {
                  audio_frames_per_pes = 4
                  audio_pids           = "492"
                  nielsen_id3_behavior = "NO_PASSTHROUGH"
                  pat_interval         = 0
                  pcr_control          = "PCR_EVERY_PES_PACKET"
                  pcr_period           = 80
                  pmt_interval         = 0
                  pmt_pid              = "480"
                  program_num          = 1
                  scte35_behavior      = "NO_PASSTHROUGH"
                  timed_metadata_behavior = "NO_PASSTHROUGH"
                  video_pid            = "481"
                }
              }
            }
            name_modifier = ""
          }
        }
        video_description_name = "video_${var.video_quality}"
      }
    }

    # Archive 출력 그룹 (선택사항)
    dynamic "output_groups" {
      for_each = var.enable_archive && var.archive_bucket_name != "" ? [1] : []
      content {
        name = "S3_ARCHIVE"

        output_group_settings {
          archive_group_settings {
            destination {
              destination_ref_id = "s3-archive"
            }
            rollover_interval = 3600
          }
        }

        outputs {
          audio_description_names = ["audio_1"]
          output_name             = "archive"
          output_settings {
            archive_output_settings {
              container_settings {
                m2ts_settings {
                  audio_buffer_model = "ATSC"
                  audio_frames_per_pes = 2
                  audio_pids = "482"
                  buffer_model = "MULTIPLEX"
                  pat_interval = 100
                  pcr_control = "PCR_EVERY_PES_PACKET"
                  pcr_period = 40
                  pmt_interval = 100
                  pmt_pid = "480"
                  program_num = 1
                  rate_mode = "CBR"
                  video_pid = "481"
                }
              }
              name_modifier = "_archive"
            }
          }
          video_description_name = "video_${var.video_quality}"
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-channel"
    }
  )
}
