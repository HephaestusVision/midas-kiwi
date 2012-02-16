/*========================================================================
  VES --- VTK OpenGL ES Rendering Toolkit

      http://www.kitware.com/ves

  Copyright 2011 Kitware, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 ========================================================================*/

package com.kitware.KiwiViewer;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.ArrayList;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.res.Configuration;
import android.content.DialogInterface;
import android.content.DialogInterface.OnDismissListener;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.os.Build;
import android.os.Environment;
import android.os.AsyncTask;
import android.util.Log;
import android.text.InputType;
import android.text.SpannableString;
import android.text.util.Linkify;
import android.text.method.LinkMovementMethod;
import android.net.Uri;
import android.view.View;
import android.view.LayoutInflater;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.ListView;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import android.app.ProgressDialog;

public class KiwiViewerActivity extends Activity {

    public static final String TAG = "KiwiViewerActivity";

    protected KiwiGLSurfaceView mView;

    protected ImageButton  mLoadButton;
    protected ImageButton  mInfoButton;
    protected ImageButton  mResetViewButton;

    protected ArrayList<String> mBuiltinDatasetNames;

    protected String fileToOpen;
    protected int datasetToOpen = -1;

    protected ProgressDialog mProgressDialog = null;

    public static final int DATASETTABLE_REQUEST_CODE = 1;


    protected void showProgressDialog() {
      showProgressDialog("Opening data...");
    }

    protected void showProgressDialog(String message) {
      mProgressDialog = new ProgressDialog(this);
      mProgressDialog.setIndeterminate(true);
      mProgressDialog.setCancelable(false);
      mProgressDialog.setMessage(message);
      mProgressDialog.show();
    }


    public void dismissProgressDialog() {
      if (mProgressDialog != null) {
        mProgressDialog.dismiss();
      }
    }


    public void showErrorDialog(String title, String message) {

      AlertDialog dialog = new AlertDialog.Builder(this).create();
      dialog.setIcon(R.drawable.alert_dialog_icon);
      dialog.setTitle(title);
      dialog.setMessage(message);
      dialog.setButton("Ok",  new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int which) {
        return;
        }});
      dialog.show();
    }


    public void showWelcomeDialog() {

      String title = getString(R.string.welcome_title);
      String message = getString(R.string.welcome_message);

      final SpannableString s = new SpannableString(message);
      Linkify.addLinks(s, Linkify.WEB_URLS);

      AlertDialog dialog = new AlertDialog.Builder(this).create();
      dialog.setTitle(title);
      dialog.setIcon(R.drawable.kiwi_small_icon);
      dialog.setMessage(s);
      dialog.setButton("Ok",  new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int which) {
        return;
        }});

      dialog.setOnDismissListener(new OnDismissListener() {
        @Override
        public void onDismiss(final DialogInterface iface) {
           maybeLoadDefaultDataset();
        }});

      dialog.show();

      ((TextView)dialog.findViewById(android.R.id.message)).setMovementMethod(LinkMovementMethod.getInstance());
    }


    public void showBrainAtlasDialog() {

      String title = getString(R.string.brainatlas_title);
      String message = getString(R.string.brainatlas_message);

      final SpannableString s = new SpannableString(message);
      Linkify.addLinks(s, Linkify.WEB_URLS);

      AlertDialog dialog = new AlertDialog.Builder(this).create();
      dialog.setIcon(R.drawable.info_icon);
      dialog.setTitle(title);
      dialog.setMessage(s);
      dialog.setButton("Ok",  new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int which) {
        return;
        }});

      dialog.show();

      ((TextView)dialog.findViewById(android.R.id.message)).setMovementMethod(LinkMovementMethod.getInstance());

    }

    public void showCanDialog() {

      String title = getString(R.string.can_title);
      String message = getString(R.string.can_message);

      AlertDialog dialog = new AlertDialog.Builder(this).create();
      dialog.setIcon(R.drawable.info_icon);
      dialog.setTitle(title);
      dialog.setMessage(message);
      dialog.setButton("Ok",  new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int which) {
        return;
        }});

      dialog.show();
    }

    public void showHeadImageDialog() {

      String title = getString(R.string.head_image_title);
      String message = getString(R.string.head_image_message);

      AlertDialog dialog = new AlertDialog.Builder(this).create();
      dialog.setIcon(R.drawable.info_icon);
      dialog.setTitle(title);
      dialog.setMessage(message);
      dialog.setButton("Ok",  new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int which) {
        return;
        }});

      dialog.show();
    }

    public void showCannotOpenAssetDialog() {

      String title = getString(R.string.cannot_open_asset_title);
      String message = getString(R.string.cannot_open_asset_message);

      AlertDialog dialog = new AlertDialog.Builder(this).create();
      dialog.setIcon(R.drawable.alert_dialog_icon);
      dialog.setTitle(title);
      dialog.setMessage(message);
      dialog.setButton(AlertDialog.BUTTON_NEUTRAL, "Ok",  new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int which) {
        return;
        }});

      dialog.setButton(AlertDialog.BUTTON_POSITIVE, "Open in Browser",  new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int which) {
          openUrlInBrowser(getString(R.string.external_data_url));
        }});

      dialog.show();
    }

    protected void openUrlInBrowser(String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        startActivity(intent);
    }


    protected void handleUriFromIntent(Uri uri) {
      if (uri != null) {
        if (uri.getScheme().equals("file")) {
          fileToOpen = uri.getPath();
        }
      }
    }


    @Override protected void onNewIntent(Intent intent) {
      super.onNewIntent(intent);
      handleUriFromIntent(intent.getData());
    }



    protected void initBuiltinDatasetNames() {

      if (mBuiltinDatasetNames == null) {
          int numberOfDatasets = KiwiNative.getNumberOfBuiltinDatasets();
          mBuiltinDatasetNames = new ArrayList<String>();
          for(int i = 0; i < numberOfDatasets; ++i) {
            mBuiltinDatasetNames.add(KiwiNative.getDatasetName(i));
          }
      }
    }

    void maybeLoadDefaultDataset() {

      if (getIntent().getData() == null) {
        String storageDir = getExternalFilesDir(null).getAbsolutePath();
        mView.postLoadDefaultDataset(this, storageDir);
      }
      else {
        KiwiNative.clearExistingDataset();
      }
    }


    @Override
    public void onConfigurationChanged(Configuration newConfig) {
      super.onConfigurationChanged(newConfig);
      mView.stopRendering();
    }


    @Override
    protected void onCreate(Bundle bundle) {
      super.onCreate(bundle);

      handleUriFromIntent(getIntent().getData());

      this.setContentView(R.layout.kiwivieweractivity);

      mView = (KiwiGLSurfaceView) this.findViewById(R.id.glSurfaceView);


      SharedPreferences prefs = getPreferences(MODE_PRIVATE);
      String versionStr = getString(R.string.version_string);

      if (!versionStr.equals(prefs.getString("version_string", ""))) {
        prefs.edit().putString("version_string", versionStr).commit();
        showWelcomeDialog();
      }
      else {
        maybeLoadDefaultDataset();
      }


      mLoadButton = (ImageButton) this.findViewById(R.id.loadDataButton);
      mInfoButton = (ImageButton) this.findViewById(R.id.infoButton);
      mResetViewButton = (ImageButton) this.findViewById(R.id.resetButton);


      mLoadButton.setOnClickListener(new Button.OnClickListener() {
          public void onClick(View v) {
              Intent datasetTableIntent = new Intent();
              datasetTableIntent.setClass(KiwiViewerActivity.this, DatasetListActivity.class);
              initBuiltinDatasetNames();
              datasetTableIntent.putExtra("com.kitware.KiwiViewer.bundle.DatasetList", mBuiltinDatasetNames);
              startActivityForResult(datasetTableIntent, DATASETTABLE_REQUEST_CODE);
          }
      });

      mInfoButton.setOnClickListener(new Button.OnClickListener() {
          public void onClick(View v) {

              Intent infoIntent = new Intent();
              infoIntent.setClass(KiwiViewerActivity.this, InfoActivity.class);
              startActivity(infoIntent);
          }
      });

      mResetViewButton.setOnClickListener(new Button.OnClickListener() {
          public void onClick(View v) {
              mView.resetCamera();
          }
      });

    }


    private void copyFile(InputStream in, OutputStream out) throws IOException {
        byte[] buffer = new byte[1024];
        int read;
        while((read = in.read(buffer)) != -1) {
          out.write(buffer, 0, read);
        }
    }


    public String copyAssetFileToStorage(String filename) {

      // todo- check storage state first, show alert dialog in case of problem
      // Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)
      //MEDIA_MOUNTED_READ_ONLY

      String storageDir = getExternalFilesDir(null).getAbsolutePath();

      String destFilename = storageDir + "/" + filename;

      File destFile = new File(destFilename);
      if (destFile.exists()) {
        return destFilename;
      }


      InputStream in = null;
      OutputStream out = null;
      try {
        in = getAssets().open(filename);
        out = new FileOutputStream(storageDir + "/" + filename);
        copyFile(in, out);
        in.close();
        in = null;
        out.flush();
        out.close();
        out = null;
      }
      catch(Exception e) {
        Log.e(TAG, e.getMessage());
      }

      return destFilename;
    }


    private class BuiltinDataLoader extends AsyncTask<String, Integer, String> {

      public int mBuiltinDatasetIndex;

      BuiltinDataLoader(int builtinDatasetIndex) {
        mBuiltinDatasetIndex = builtinDatasetIndex;
      }

      protected String doInBackground(String... filename) {

        if (filename[0].equals("textured_sphere.vtp")) {
          copyEarthAssets();
        }
        else if (filename[0].equals("model_info.txt")) {
          copyBrainAtlasAssets();
        }
        else if (filename[0].equals("can0000.vtp")) {
          copyCanAssets();
        }

        return copyAssetFileToStorage(filename[0]);
      }

      protected void onPreExecute() {
        showProgressDialog();
      }

      protected void onPostExecute(String filename) {
        mView.loadDataset(filename, mBuiltinDatasetIndex, KiwiViewerActivity.this);
      }
    }


    public void loadDataset(int builtinDatasetIndex) {

      String filename = KiwiNative.getDatasetFilename(builtinDatasetIndex);

      // don't attempt to open large asset files on android api 8
      int sdkVersion = Build.VERSION.SDK_INT;
      if (sdkVersion <= 8
          && (filename.equals("visible-woman-hand.vtp")
              || filename.equals("AppendedKneeData.vtp")
              || filename.equals("cturtle.vtp")
              || filename.equals("model_info.txt"))) {
        showCannotOpenAssetDialog();
        return;
      }

      new BuiltinDataLoader(builtinDatasetIndex).execute(filename);
    }


    public void loadDataset(String filename) {
      showProgressDialog();
      mView.loadDataset(filename, KiwiViewerActivity.this);
    }

    public void postLoadDataset(String filename, boolean result, String errorTitle, String errorMessage) {
      dismissProgressDialog();
      if (!result) {
        showErrorDialog(errorTitle, errorMessage);
      }
      else {
        if (filename.endsWith("model_info.txt")) {
          showBrainAtlasDialog();
        }
        else if (filename.endsWith("can0000.vtp")) {
          showCanDialog();
        }
        else if (filename.endsWith("head.vti")) {
          showHeadImageDialog();
        }
      }
    }


    @Override protected void onPause() {
        super.onPause();
        mView.onPause();
    }

    @Override protected void onResume() {
        super.onResume();
        mView.onResume();

        if (fileToOpen != null) {
          loadDataset(fileToOpen);
          fileToOpen = null;
        }
        else if (datasetToOpen >= 0) {
          loadDataset(datasetToOpen);
          datasetToOpen = -1;
        }
    }

    /**
     * Get results from the dataset dialog
     */
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
      Bundle curBundle = null;

      if (data != null) {
        curBundle = data.getExtras();
      }
      if (requestCode == DATASETTABLE_REQUEST_CODE && curBundle != null
          && curBundle.containsKey("com.kitware.KiwiViewer.bundle.DatasetName")) {

        String name = curBundle.getString("com.kitware.KiwiViewer.bundle.DatasetName");
        int offset = curBundle.getInt("com.kitware.KiwiViewer.bundle.DatasetOffset");
        datasetToOpen = offset;
      }

      super.onActivityResult(requestCode, resultCode, data);
    }


  protected void copyEarthAssets() {
    copyAssetFileToStorage("earth.jpg");
  }

  protected void copyCanAssets() {
    copyAssetFileToStorage("can0000.vtp");
    copyAssetFileToStorage("can0001.vtp");
    copyAssetFileToStorage("can0002.vtp");
    copyAssetFileToStorage("can0003.vtp");
    copyAssetFileToStorage("can0004.vtp");
    copyAssetFileToStorage("can0005.vtp");
    copyAssetFileToStorage("can0006.vtp");
    copyAssetFileToStorage("can0007.vtp");
    copyAssetFileToStorage("can0008.vtp");
    copyAssetFileToStorage("can0009.vtp");
    copyAssetFileToStorage("can0010.vtp");
    copyAssetFileToStorage("can0011.vtp");
    copyAssetFileToStorage("can0012.vtp");
    copyAssetFileToStorage("can0013.vtp");
    copyAssetFileToStorage("can0014.vtp");
    copyAssetFileToStorage("can0015.vtp");
    copyAssetFileToStorage("can0016.vtp");
    copyAssetFileToStorage("can0017.vtp");
    copyAssetFileToStorage("can0018.vtp");
    copyAssetFileToStorage("can0019.vtp");
    copyAssetFileToStorage("can0020.vtp");
    copyAssetFileToStorage("can0021.vtp");
    copyAssetFileToStorage("can0022.vtp");
    copyAssetFileToStorage("can0023.vtp");
    copyAssetFileToStorage("can0024.vtp");
    copyAssetFileToStorage("can0025.vtp");
    copyAssetFileToStorage("can0026.vtp");
    copyAssetFileToStorage("can0027.vtp");
    copyAssetFileToStorage("can0028.vtp");
    copyAssetFileToStorage("can0029.vtp");
    copyAssetFileToStorage("can0030.vtp");
    copyAssetFileToStorage("can0031.vtp");
    copyAssetFileToStorage("can0032.vtp");
    copyAssetFileToStorage("can0033.vtp");
    copyAssetFileToStorage("can0034.vtp");
    copyAssetFileToStorage("can0035.vtp");
    copyAssetFileToStorage("can0036.vtp");
    copyAssetFileToStorage("can0037.vtp");
    copyAssetFileToStorage("can0038.vtp");
    copyAssetFileToStorage("can0039.vtp");
    copyAssetFileToStorage("can0040.vtp");
    copyAssetFileToStorage("can0041.vtp");
    copyAssetFileToStorage("can0042.vtp");
    copyAssetFileToStorage("can0043.vtp");
  }

  protected void copyBrainAtlasAssets() {
    copyAssetFileToStorage("Skin.vtp");
    copyAssetFileToStorage("VPL_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("VPL_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("VPM_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("VPM_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("abducent_nerve_L.vtp");
    copyAssetFileToStorage("abducent_nerve_R.vtp");
    copyAssetFileToStorage("accessory_nerve_L.vtp");
    copyAssetFileToStorage("accessory_nerve_R.vtp");
    copyAssetFileToStorage("amygdaloid_body_L.vtp");
    copyAssetFileToStorage("amygdaloid_body_R.vtp");
    copyAssetFileToStorage("angular_gyrus_inferior_parietal_lobule_L.vtp");
    copyAssetFileToStorage("angular_gyrus_inferior_parietal_lobule_R.vtp");
    copyAssetFileToStorage("anterior_commissure.vtp");
    copyAssetFileToStorage("anterior_substantia_perforata_L.vtp");
    copyAssetFileToStorage("anterior_substantia_perforata_R.vtp");
    copyAssetFileToStorage("anterior_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("anterior_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("atlas.vtp");
    copyAssetFileToStorage("axis.vtp");
    copyAssetFileToStorage("caudate_nucleus_L.vtp");
    copyAssetFileToStorage("caudate_nucleus_R.vtp");
    copyAssetFileToStorage("centromedian_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("centromedian_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("cerebellar_hemisphere_L.vtp");
    copyAssetFileToStorage("cerebellar_hemisphere_R.vtp");
    copyAssetFileToStorage("cerebellar_tonsil_L.vtp");
    copyAssetFileToStorage("cerebellar_tonsil_R.vtp");
    copyAssetFileToStorage("cerebellar_vermis.vtp");
    copyAssetFileToStorage("cerebellar_white_matter.vtp");
    copyAssetFileToStorage("cingulate_gyrus_L.vtp");
    copyAssetFileToStorage("cingulate_gyrus_R.vtp");
    copyAssetFileToStorage("corpus_callosum.vtp");
    copyAssetFileToStorage("corticospinal_tract_L.vtp");
    copyAssetFileToStorage("corticospinal_tract_R.vtp");
    copyAssetFileToStorage("dentate_nucleus_L.vtp");
    copyAssetFileToStorage("dentate_nucleus_R.vtp");
    copyAssetFileToStorage("dorsomedial_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("dorsomedial_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("external_capsule_L.vtp");
    copyAssetFileToStorage("external_capsule_R.vtp");
    copyAssetFileToStorage("eyeball_L.vtp");
    copyAssetFileToStorage("eyeball_R.vtp");
    copyAssetFileToStorage("facial_nerve_L.vtp");
    copyAssetFileToStorage("facial_nerve_R.vtp");
    copyAssetFileToStorage("fornix.vtp");
    copyAssetFileToStorage("fourth_ventricle_aqueduct.vtp");
    copyAssetFileToStorage("globus_pallidus_L.vtp");
    copyAssetFileToStorage("globus_pallidus_R.vtp");
    copyAssetFileToStorage("glossopharyngeal_nerve_L.vtp");
    copyAssetFileToStorage("glossopharyngeal_nerve_R.vtp");
    copyAssetFileToStorage("hemispheric_white_matter.vtp");
    copyAssetFileToStorage("hippocampus_L.vtp");
    copyAssetFileToStorage("hippocampus_R.vtp");
    copyAssetFileToStorage("hypoglossal_nerve_L.vtp");
    copyAssetFileToStorage("hypoglossal_nerve_R.vtp");
    copyAssetFileToStorage("hypothalamus.vtp");
    copyAssetFileToStorage("inferior_cerebellar_peduncle_L.vtp");
    copyAssetFileToStorage("inferior_cerebellar_peduncle_R.vtp");
    copyAssetFileToStorage("inferior_colliculus_L.vtp");
    copyAssetFileToStorage("inferior_colliculus_R.vtp");
    copyAssetFileToStorage("inferior_frontal_gyrus_L.vtp");
    copyAssetFileToStorage("inferior_frontal_gyrus_R.vtp");
    copyAssetFileToStorage("inferior_temporal_gyrus_L.vtp");
    copyAssetFileToStorage("inferior_temporal_gyrus_R.vtp");
    copyAssetFileToStorage("insula_L.vtp");
    copyAssetFileToStorage("insula_R.vtp");
    copyAssetFileToStorage("internal_capsule_L.vtp");
    copyAssetFileToStorage("internal_capsule_R.vtp");
    copyAssetFileToStorage("internal_capsule_post_L.vtp");
    copyAssetFileToStorage("internal_capsule_post_R.vtp");
    copyAssetFileToStorage("internal_medullar_lamina_L.vtp");
    copyAssetFileToStorage("internal_medullar_lamina_R.vtp");
    copyAssetFileToStorage("lateral_dorsal_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("lateral_dorsal_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("lateral_geniculate_body_L.vtp");
    copyAssetFileToStorage("lateral_geniculate_body_R.vtp");
    copyAssetFileToStorage("lateral_occipitotemporal_gyrus_L.vtp");
    copyAssetFileToStorage("lateral_occipitotemporal_gyrus_R.vtp");
    copyAssetFileToStorage("lateral_posterior_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("lateral_posterior_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("lateral_ventricle_L.vtp");
    copyAssetFileToStorage("lateral_ventricle_R.vtp");
    copyAssetFileToStorage("mamillary_body_L.vtp");
    copyAssetFileToStorage("mamillary_body_R.vtp");
    copyAssetFileToStorage("medial_geniculate_body_L.vtp");
    copyAssetFileToStorage("medial_geniculate_body_R.vtp");
    copyAssetFileToStorage("medial_occipitotemporal_parahippocampal_gyrus_L.vtp");
    copyAssetFileToStorage("medial_occipitotemporal_parahippocampal_gyrus_R.vtp");
    copyAssetFileToStorage("medulla_oblongata.vtp");
    copyAssetFileToStorage("midbrain.vtp");
    copyAssetFileToStorage("middle_cerebellar_peduncle_L.vtp");
    copyAssetFileToStorage("middle_cerebellar_peduncle_R.vtp");
    copyAssetFileToStorage("middle_frontal_gyrus_L.vtp");
    copyAssetFileToStorage("middle_frontal_gyrus_R.vtp");
    copyAssetFileToStorage("middle_temporal_gyrus_L.vtp");
    copyAssetFileToStorage("middle_temporal_gyrus_R.vtp");
    copyAssetFileToStorage("model_info.txt");
    copyAssetFileToStorage("nucleus_accumbens_L.vtp");
    copyAssetFileToStorage("nucleus_accumbens_R.vtp");
    copyAssetFileToStorage("nucleus_habenulae_L.vtp");
    copyAssetFileToStorage("nucleus_habenulae_R.vtp");
    copyAssetFileToStorage("occipital_lobe_L.vtp");
    copyAssetFileToStorage("occipital_lobe_R.vtp");
    copyAssetFileToStorage("occulomotor_nerve_L.vtp");
    copyAssetFileToStorage("occulomotor_nerve_R.vtp");
    copyAssetFileToStorage("optic_chiasm.vtp");
    copyAssetFileToStorage("optic_nerve_L.vtp");
    copyAssetFileToStorage("optic_nerve_R.vtp");
    copyAssetFileToStorage("optic_radiation_L.vtp");
    copyAssetFileToStorage("optic_radiation_R.vtp");
    copyAssetFileToStorage("optic_tract_L.vtp");
    copyAssetFileToStorage("optic_tract_R.vtp");
    copyAssetFileToStorage("orbital_gyri_gyrus_rectus_L.vtp");
    copyAssetFileToStorage("orbital_gyri_gyrus_rectus_R.vtp");
    copyAssetFileToStorage("pellucid_septum.vtp");
    copyAssetFileToStorage("pineal_body.vtp");
    copyAssetFileToStorage("pituitary_gland.vtp");
    copyAssetFileToStorage("pons.vtp");
    copyAssetFileToStorage("postcentral_gyrus_L.vtp");
    copyAssetFileToStorage("postcentral_gyrus_R.vtp");
    copyAssetFileToStorage("posterior_commissure.vtp");
    copyAssetFileToStorage("posterior_substantia_perforata.vtp");
    copyAssetFileToStorage("precentral_gyrus_L.vtp");
    copyAssetFileToStorage("precentral_gyrus_R.vtp");
    copyAssetFileToStorage("pulvinar_L.vtp");
    copyAssetFileToStorage("pulvinar_R.vtp");
    copyAssetFileToStorage("putamen_L.vtp");
    copyAssetFileToStorage("putamen_R.vtp");
    copyAssetFileToStorage("red_nucleus_L.vtp");
    copyAssetFileToStorage("red_nucleus_R.vtp");
    copyAssetFileToStorage("septal_nucleus_L.vtp");
    copyAssetFileToStorage("septal_nucleus_R.vtp");
    copyAssetFileToStorage("skull_bone.vtp");
    copyAssetFileToStorage("substantia_nigra_L.vtp");
    copyAssetFileToStorage("substantia_nigra_R.vtp");
    copyAssetFileToStorage("superior_cerebellar_peduncle_L.vtp");
    copyAssetFileToStorage("superior_cerebellar_peduncle_R.vtp");
    copyAssetFileToStorage("superior_colliculus_L.vtp");
    copyAssetFileToStorage("superior_colliculus_R.vtp");
    copyAssetFileToStorage("superior_frontal_gyrus_L.vtp");
    copyAssetFileToStorage("superior_frontal_gyrus_R.vtp");
    copyAssetFileToStorage("superior_medullar_velum.vtp");
    copyAssetFileToStorage("superior_parietal_lobule_L.vtp");
    copyAssetFileToStorage("superior_parietal_lobule_R.vtp");
    copyAssetFileToStorage("superior_temporal_gyrus_ant_L.vtp");
    copyAssetFileToStorage("superior_temporal_gyrus_ant_R.vtp");
    copyAssetFileToStorage("superior_temporal_gyrus_post_L.vtp");
    copyAssetFileToStorage("superior_temporal_gyrus_post_R.vtp");
    copyAssetFileToStorage("supramarginal_gyrus_inferior_parietal_lobule_L.vtp");
    copyAssetFileToStorage("supramarginal_gyrus_inferior_parietal_lobule_R.vtp");
    copyAssetFileToStorage("temporal_pole_L.vtp");
    copyAssetFileToStorage("temporal_pole_R.vtp");
    copyAssetFileToStorage("third_ventricle.vtp");
    copyAssetFileToStorage("trigeminal_nerve_L.vtp");
    copyAssetFileToStorage("trigeminal_nerve_R.vtp");
    copyAssetFileToStorage("trochlearis_nerve_L.vtp");
    copyAssetFileToStorage("trochlearis_nerve_R.vtp");
    copyAssetFileToStorage("vagal_nerve_L.vtp");
    copyAssetFileToStorage("vagal_nerve_R.vtp");
    copyAssetFileToStorage("ventral_anterior_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("ventral_anterior_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("ventral_lateral_thalamic_nucleus_L.vtp");
    copyAssetFileToStorage("ventral_lateral_thalamic_nucleus_R.vtp");
    copyAssetFileToStorage("vestibulocochlear_nerve_L.vtp");
    copyAssetFileToStorage("vestibulocochlear_nerve_R.vtp");
  }

}
