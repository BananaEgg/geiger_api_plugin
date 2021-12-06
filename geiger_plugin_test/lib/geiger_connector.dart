import 'dart:convert';
import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class GeigerConnector {
  late GeigerApi? geigerApi;
  late StorageController? storageController;







  Future<void> initGeigerAPI() async {
    try {
      flushGeigerApiCache();
      geigerApi = await getGeigerApi(
          '', GeigerApi.masterId, Declaration.doNotShareData);
      // geigerApi = await getGeigerApi(
      //     '', 'miCyberrangePlugin', Declaration.doNotShareData);
      if (geigerApi != null) {
        storageController = geigerApi!.getStorage();
        if (storageController == null) {
          log('Could not get the storageController');
        }
      } else {
        log('Could not get the GeigerAPI');
      }
    } catch (e) {
      log('Failed to get the GeigerAPI');
      log(e.toString());
    }

    await addChildPath(':', 'Chatbot');
    // await addChildPath(':Chatbot', 'reports');
    // await insertDummyData();
  }

  Future insertDummyData() async {
    Map data = {
      "type": "URL",
      "address": "badguy@gmail.com",
      "sensor": "kaspersky"
    };
    try {
      await writeToGeigerStorage(data, 'report01', ':Chatbot:reports');
    } catch (e) {
      print("Error adding Storage Data: " + e.toString());
    }

    try {
      Map? data =
          await readDataFromGeigerStorage('report01', ':Chatbot:reports');
      print(data);
    } catch (e) {
      print("Error retriving Storage Data: " + e.toString());
    }

    try {
      List? data = await getNodeValues(':Chatbot:reports');
      print(data);
    } catch (e) {
      print("Error retriving Storage Data: " + e.toString());
    }
  }

  Future writeToGeigerStorage(Map data, String key, String nodePath) async {
    log('Trying to get the data node');
    try {
      log('Found the data node - Going to write the data');
      Node node = await storageController!.get(nodePath);

      node.addOrUpdateValue(NodeValueImpl(key, jsonEncode(data)));
      await storageController!.update(node);
    } catch (e) {
      log(e.toString());
      log('Cannot find the data node - Going to create a new one');

      Node node = NodeImpl(nodePath, '');
      await node.addValue(NodeValueImpl(key, jsonEncode(data)));
      await storageController!.add(node);
    }
  }

  Future<Map?> readDataFromGeigerStorage(String key, String nodePath) async {
    log('Trying to get the data node');
    try {
      log('Found the data node - Going to get the data');
      Node node = await storageController!.get(nodePath);
      NodeValue? nValue = await node.getValue(key);
      if (nValue != null) {
        return jsonDecode(nValue.value);
      } else {
        log('Failed to retrieve the node value');
      }
    } catch (e) {
      log('Failed to retrieve the data node');
      log(e.toString());
    }
    return null;
  }

  Future addChildPath(String parent, String chaild) async {
    try {
      Node node = await storageController!.get(parent);
      String path = parent + ':' + chaild;
      Node childNode = NodeImpl(path, '');

      await node.addChild(childNode);
      //update node
      await storageController!.addOrUpdate(node);
    } catch (e) {
      log("Error adding chaild to " + parent + ' , ' + e.toString());
    }
  }

  Future<List?> getNodeValues(String nodePath) async {
    log('Trying to get the data node');
    try {
      log('Found the data node - Going to get the data');
      Node node = await storageController!.get(nodePath);
      List t = [];
      Map nodeVals = await node.getValues();
      nodeVals.forEach((key, value) {
        return t.add({'key': key, 'val': jsonDecode(value)});
      });
      if (t.isNotEmpty) {
        return t;
      } else {
        log('Failed to retrieve the node value');
      }
    } catch (e) {
      log('Failed to retrieve the data node');
      log(e.toString());
    }
    return null;
  }
}
