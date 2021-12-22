import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class GeigerConnector {
  late GeigerApi? geigerApi;
  late StorageController? storageController;

  Future<void> initGeigerAPI() async {
    try {
      // flushGeigerApiCache();
      geigerApi = await getGeigerApi(
          '', GeigerApi.masterId, Declaration.doNotShareData);
      // geigerApi = await getGeigerApi(
      //     '', 'miCyberrangePlugin', Declaration.doNotShareData);
    } catch (e) {
      print(e.toString());
    } finally {
      try {
        Timer(Duration(seconds: 1), () => print('done'));

        storageController = geigerApi!.getStorage();

        Timer(Duration(seconds: 1), () => print('done'));
      } catch (e) {
        log('Failed to get the GeigerAPI');
        log(e.toString());
      } finally {
        try {
          await addNodeToRoot('Chatbot');
          await addChildPath(':Chatbot', 'reports');
             await addChildPath(':Chatbot', 'sensor');
          // await testNodeCreation(':Chatbot:sensor');
        } catch (e) {
          print("Error adding Storage Node path: " + e.toString());
        } finally {
          await insertDummyData();
          List? t = await getNodeValues(':Chatbot:sensor');
          print(t);
        }
      }
    }
  }

  Future insertDummyData() async {
    List data = [
      {
        'key': "aaa",
        'val': {"type": "URL", "value": "badguy@gmail.com", "sensor": "GGX"}
      },
      {
        'key': "bbb",
        'val': {
          "type": "application",
          "value": "badguy@gmail.com",
          "sensor": "kaspersky"
        }
      },
      {
        'key': "ccc",
        'val': {"type": "file", "value": "virus.fx", "sensor": "QQW"}
      },
      {
        'key': "ddd",
        'val': {
          "type": "URL",
          "value": "bad@gmail.com",
          "sensor": "kaspersky"
        }
      }
    ];
    for (var item in data) {
      try {
        await writeToGeigerStorage(item['val'], item['key'], ':Chatbot:sensor');
      } catch (e) {
        log(e.toString());

        print("Error adding Storage Data: " + e.toString());
      }
    }

    try {
      Map? data = await readDataFromGeigerStorage("ccc", ':Chatbot:sensor');
      print(data);
    } catch (e) {
      print("Error retriving Storage Data: " + e.toString());
    }
  }

  Future testNodeCreation(String nodePath) async {
    log('Testing node creation ' + nodePath);
    try {
      log('Found the data node - Going to write the data');
      Node node = await storageController!.get(nodePath);

      node.addOrUpdateValue(NodeValueImpl('test', jsonEncode('test-data')));
      await storageController!.update(node);
    } catch (e) {
      log(e.toString());
      log('Cannot find node ' + nodePath);

      // Node node = NodeImpl(nodePath, '');
      // await node.addOrUpdateValue(NodeValueImpl(key, jsonEncode(data)));
      // await storageController!.addOrUpdate(node);
    }
  }

  Future writeToGeigerStorage(Map data, String key, String nodePath) async {
    log('Trying to get the data node');
    try {
      log('Found the data node - Going to write the data');
      Node node = await storageController!.get(nodePath);

      node.addOrUpdateValue(NodeValueImpl(key, jsonEncode(data)));
      await storageController!.addOrUpdate(node);
    } catch (e) {
      log(e.toString());
      log('Cannot find the data node ' +
          nodePath +
          ', key: ' +
          key +
          ' - Going to create a new one');

      Node node = NodeImpl(nodePath, '');
      await node.addOrUpdateValue(NodeValueImpl(key, jsonEncode(data)));
      await storageController!.addOrUpdate(node);
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

  Future addNodeToRoot(String chaild) async {
    try {
      Node rootNode = await storageController!.get(':');

      Node childNode = NodeImpl(chaild, '');

      await rootNode.addChild(childNode);
      //update node
      await storageController!.addOrUpdate(rootNode);
    } catch (e) {
      log(e.toString());
    }
  }

  Future addChildPath(String parent, String chaild) async {
    try {
      Node node = await storageController!.get(parent);
      Node childNode = NodeImpl(chaild, '');
      await node.addChild(childNode);
      await storageController!.addOrUpdate(node);
    } catch (e) {
      log(e.toString());
    }
  }

  Future<List?> getNodeValues(String nodePath) async {
    try {
      Node node = await storageController!.get(nodePath);
      Map<String, NodeValue> nodeValues = await node.getValues();
      Map<String, NodeValue> values = await node.getValues();

      if (values.isNotEmpty) {
        return values.entries
            .map((entry) => {
                  entry.key : jsonDecode(values[entry.key]!.value)
                })
            .toList();
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
